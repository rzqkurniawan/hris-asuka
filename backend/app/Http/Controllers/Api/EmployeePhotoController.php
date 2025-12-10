<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\File;

class EmployeePhotoController extends Controller
{
    // Local cache path - synced from GCP via rsync (run by cron as hrisapi user)
    private $localCachePath = '/var/www/hris-asuka/backend/storage/app/photo-cache/';

    /**
     * Get employee photo from local cache (synced from GCP)
     */
    public function getPhoto($filename)
    {
        return $this->servePhotoFromCache($filename);
    }

    /**
     * Get employee identity/KTP photo from local cache (synced from GCP)
     */
    public function getIdentityPhoto($filename)
    {
        return $this->servePhotoFromCache($filename);
    }

    /**
     * Serve photo from local cache
     */
    private function servePhotoFromCache($filename)
    {
        try {
            // Sanitize filename to prevent directory traversal
            $filename = basename($filename);

            // Local cached file path
            $localFilePath = $this->localCachePath . $filename;

            // Check if file exists in local cache
            if (!file_exists($localFilePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Photo not found'
                ], 404);
            }

            // Get file extension and set appropriate content type
            $extension = strtolower(pathinfo($localFilePath, PATHINFO_EXTENSION));
            $mimeTypes = [
                'jpg' => 'image/jpeg',
                'jpeg' => 'image/jpeg',
                'png' => 'image/png',
                'gif' => 'image/gif',
                'pdf' => 'application/pdf',
            ];

            $contentType = $mimeTypes[$extension] ?? 'application/octet-stream';

            // Return the file
            return response()->file($localFilePath, [
                'Content-Type' => $contentType,
                'Cache-Control' => 'public, max-age=86400', // Cache for 24 hours
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error loading photo: ' . $e->getMessage()
            ], 500);
        }
    }
}
