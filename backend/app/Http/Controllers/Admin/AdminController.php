<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class AdminController extends Controller
{
    // Show login form
    public function showLogin()
    {
        if (Auth::check() && Auth::user()->is_admin) {
            return redirect()->route('admin.dashboard');
        }
        return view('admin.login');
    }

    // Handle login
    public function login(Request $request)
    {
        $request->validate([
            'username' => 'required',
            'password' => 'required',
        ]);

        if (Auth::attempt(['username' => $request->username, 'password' => $request->password])) {
            if (Auth::user()->is_admin) {
                return redirect()->route('admin.dashboard');
            }
            Auth::logout();
            return back()->with('error', 'You are not authorized to access admin panel');
        }

        return back()->with('error', 'Invalid credentials');
    }

    // Logout
    public function logout()
    {
        Auth::logout();
        return redirect()->route('admin.login');
    }

    // Dashboard
    public function dashboard()
    {
        $totalUsers = User::count();
        $activeUsers = User::where('is_active', true)->count();
        $totalEmployees = DB::connection('c3ais')->table('ki_employee')
            ->where('working_status', 'Active')->count();
        $usersWithAccounts = User::whereNotNull('employee_id')->count();
        $employeesWithoutAccount = $totalEmployees - $usersWithAccounts;

        return view('admin.dashboard', compact(
            'totalUsers',
            'activeUsers',
            'totalEmployees',
            'usersWithAccounts',
            'employeesWithoutAccount'
        ));
    }

    // Users list
    public function users(Request $request)
    {
        $query = User::with('employee');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('username', 'like', "%{$search}%")
                  ->orWhere('employee_number', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(20);

        return view('admin.users.index', compact('users'));
    }

    // Show create form
    public function createUser()
    {
        return view('admin.users.create');
    }

    // Store new user
    public function storeUser(Request $request)
    {
        $request->validate([
            'employee_id' => 'required|integer|unique:users',
            'username' => 'required|string|min:6|max:12|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $employee = Employee::find($request->employee_id);
        if (!$employee) {
            return back()->with('error', 'Employee not found');
        }

        User::create([
            'employee_id' => $request->employee_id,
            'employee_number' => $employee->employee_number,
            'username' => $request->username,
            'password' => Hash::make($request->password),
            'is_active' => true,
            'is_admin' => $request->has('is_admin'),
        ]);

        return redirect()->route('admin.users')->with('success', 'User created successfully');
    }

    // Show edit form
    public function editUser($id)
    {
        $user = User::with('employee')->findOrFail($id);
        return view('admin.users.edit', compact('user'));
    }

    // Update user
    public function updateUser(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'username' => 'required|string|min:6|max:12|unique:users,username,'.$id,
        ]);

        $user->username = $request->username;
        $user->is_active = $request->has('is_active');
        $user->is_admin = $request->has('is_admin');

        if ($request->filled('password')) {
            $request->validate(['password' => 'min:8|confirmed']);
            $user->password = Hash::make($request->password);
        }

        $user->save();

        return redirect()->route('admin.users')->with('success', 'User updated successfully');
    }

    // Delete user
    public function deleteUser($id)
    {
        $user = User::findOrFail($id);
        
        // Prevent deleting own account
        if ($user->id === Auth::id()) {
            return back()->with('error', 'Cannot delete your own account');
        }

        $user->delete();
        return redirect()->route('admin.users')->with('success', 'User deleted successfully');
    }

    // Export users to CSV
    public function exportUsers()
    {
        $users = User::with('employee')->get();
        
        $filename = 'users_export_'.date('Y-m-d').'.csv';
        
        header('Content-Type: text/csv');
        header('Content-Disposition: attachment; filename="'.$filename.'"');
        
        $output = fopen('php://output', 'w');
        
        // Header
        fputcsv($output, ['ID', 'Username', 'Employee Number', 'Full Name', 'Status', 'Is Admin', 'Created At']);
        
        // Data
        foreach ($users as $user) {
            fputcsv($output, [
                $user->id,
                $user->username,
                $user->employee_number,
                $user->employee ? $user->employee->fullname : '-',
                $user->is_active ? 'Active' : 'Inactive',
                $user->is_admin ? 'Yes' : 'No',
                $user->created_at,
            ]);
        }
        
        fclose($output);
        exit();
    }
}
