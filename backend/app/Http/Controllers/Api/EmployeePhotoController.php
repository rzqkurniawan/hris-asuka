<?php

namespace App\Http\Controllers\Api;

use Illuminate\Http\Request;
use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\File;

class EmployeePhotoController extends Controller
{
    /**
     * Get employee photo from mounted GCP storage
     */
    public function getPhoto($filename)
    {
        try {
            // Sanitize filename to prevent directory traversal
            $filename = basename($filename);

            // Path to the mounted photo directory
            $filePath = '/var/www/clients/client3/web5/web/protected/attachments/employeePhoto/' . $filename;

            // Check if file exists
            if (!file_exists($filePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Photo not found'
                ], 404);
            }

            // Get file extension and set appropriate content type
            $extension = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
            $mimeTypes = [
                'jpg' => 'image/jpeg',
                'jpeg' => 'image/jpeg',
                'png' => 'image/png',
                'gif' => 'image/gif',
            ];

            $contentType = $mimeTypes[$extension] ?? 'application/octet-stream';

            // Return the file
            return response()->file($filePath, [
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

    /**
     * Get employee identity/KTP photo from mounted GCP storage
     */
    public function getIdentityPhoto($filename)
    {
        try {
            // Sanitize filename to prevent directory traversal
            $filename = basename($filename);

            // Path to the mounted photo directory (same as employee photos)
            $filePath = '/var/www/clients/client3/web5/web/protected/attachments/employeePhoto/' . $filename;

            // Check if file exists
            if (!file_exists($filePath)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Identity photo not found'
                ], 404);
            }

            // Get file extension and set appropriate content type
            $extension = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
            $mimeTypes = [
                'jpg' => 'image/jpeg',
                'jpeg' => 'image/jpeg',
                'png' => 'image/png',
                'gif' => 'image/gif',
            ];

            $contentType = $mimeTypes[$extension] ?? 'application/octet-stream';

            // Return the file
            return response()->file($filePath, [
                'Content-Type' => $contentType,
                'Cache-Control' => 'public, max-age=86400', // Cache for 24 hours
            ]);

        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error loading identity photo: ' . $e->getMessage()
            ], 500);
        }
    }
}
