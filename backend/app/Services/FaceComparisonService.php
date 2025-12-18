<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class FaceComparisonService
{
    /**
     * Python script path for face comparison
     */
    protected string $scriptPath;

    public function __construct()
    {
        $this->scriptPath = base_path('scripts/compare_faces.py');
    }

    /**
     * Compare two face images and return similarity score
     *
     * @param string $image1Path Path to first image (reference)
     * @param string $image2Base64 Base64 encoded second image (captured)
     * @return array ['success' => bool, 'match' => bool, 'confidence' => float, 'message' => string]
     */
    public function compareFaces(string $image1Path, string $image2Base64): array
    {
        try {
            // Validate reference image exists
            if (!file_exists($image1Path)) {
                Log::warning('FaceComparison: Reference image not found', ['path' => $image1Path]);
                return [
                    'success' => false,
                    'match' => false,
                    'confidence' => 0,
                    'message' => 'Foto referensi tidak ditemukan',
                ];
            }

            // Decode base64 and save to temp file
            $image2Data = base64_decode($image2Base64);
            if ($image2Data === false) {
                return [
                    'success' => false,
                    'match' => false,
                    'confidence' => 0,
                    'message' => 'Format gambar tidak valid',
                ];
            }

            $tempFile = tempnam(sys_get_temp_dir(), 'face_compare_');
            file_put_contents($tempFile, $image2Data);

            try {
                // Run Python face comparison script
                $result = $this->runFaceComparison($image1Path, $tempFile);
                return $result;
            } finally {
                // Clean up temp file
                if (file_exists($tempFile)) {
                    unlink($tempFile);
                }
            }
        } catch (\Exception $e) {
            Log::error('FaceComparison error', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return [
                'success' => false,
                'match' => false,
                'confidence' => 0,
                'message' => 'Terjadi kesalahan saat memproses verifikasi wajah',
            ];
        }
    }

    /**
     * Run Python face comparison script
     */
    protected function runFaceComparison(string $image1Path, string $image2Path): array
    {
        // Ensure script exists
        if (!file_exists($this->scriptPath)) {
            Log::error('Face comparison script not found', ['path' => $this->scriptPath]);
            return [
                'success' => false,
                'match' => false,
                'confidence' => 0,
                'message' => 'Script perbandingan wajah tidak ditemukan',
            ];
        }

        // Build command
        $command = sprintf(
            'python3 %s %s %s 2>&1',
            escapeshellarg($this->scriptPath),
            escapeshellarg($image1Path),
            escapeshellarg($image2Path)
        );

        // Execute command
        $output = [];
        $returnVar = 0;
        exec($command, $output, $returnVar);

        $outputStr = implode("\n", $output);

        Log::info('Face comparison executed', [
            'command' => $command,
            'return_var' => $returnVar,
            'output' => $outputStr,
        ]);

        if ($returnVar !== 0) {
            Log::error('Face comparison script failed', [
                'return_var' => $returnVar,
                'output' => $outputStr,
            ]);
            return [
                'success' => false,
                'match' => false,
                'confidence' => 0,
                'message' => 'Gagal memproses perbandingan wajah: ' . $outputStr,
            ];
        }

        // Parse JSON output from Python script
        $result = json_decode($outputStr, true);

        if (json_last_error() !== JSON_ERROR_NONE) {
            Log::error('Failed to parse face comparison result', [
                'output' => $outputStr,
                'json_error' => json_last_error_msg(),
            ]);
            return [
                'success' => false,
                'match' => false,
                'confidence' => 0,
                'message' => 'Gagal memproses hasil perbandingan wajah',
            ];
        }

        return $result;
    }

    /**
     * Get the minimum required confidence for face match
     */
    public function getMinConfidence(): float
    {
        return 75.0; // 75% minimum similarity required
    }
}
