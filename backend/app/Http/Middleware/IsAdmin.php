<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class IsAdmin
{
    public function handle(Request $request, Closure $next)
    {
        // Check if user is logged in and is admin
        if (!auth()->check() || !auth()->user()->is_admin) {
            return redirect()->route('admin.login')->with('error', 'Unauthorized access');
        }

        return $next($request);
    }
}
