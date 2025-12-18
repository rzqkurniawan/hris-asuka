<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
        apiPrefix: 'api',
    )
    ->withMiddleware(function (Middleware $middleware) {
        $middleware->alias([
            'admin' => \App\Http\Middleware\IsAdmin::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Hide error details in production for API requests
        $exceptions->render(function (Throwable $e, Request $request) {
            if ($request->is('api/*') || $request->expectsJson()) {
                $statusCode = 500;

                if ($e instanceof HttpException) {
                    $statusCode = $e->getStatusCode();
                } elseif ($e instanceof \Illuminate\Validation\ValidationException) {
                    return null; // Let Laravel handle validation exceptions normally
                } elseif ($e instanceof \Illuminate\Auth\AuthenticationException) {
                    $statusCode = 401;
                } elseif ($e instanceof \Illuminate\Auth\Access\AuthorizationException) {
                    $statusCode = 403;
                } elseif ($e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException) {
                    $statusCode = 404;
                }

                // In production, hide detailed error messages
                $message = app()->environment('production')
                    ? 'An error occurred. Please try again later.'
                    : $e->getMessage();

                // Log the actual error for debugging
                if (app()->environment('production')) {
                    \Log::error('API Exception', [
                        'message' => $e->getMessage(),
                        'file' => $e->getFile(),
                        'line' => $e->getLine(),
                        'url' => $request->fullUrl(),
                        'method' => $request->method(),
                    ]);
                }

                return response()->json([
                    'success' => false,
                    'message' => $message,
                ], $statusCode);
            }

            return null; // Let Laravel handle non-API exceptions normally
        });
    })->create();
