<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run()
    {
        // Create admin user
        User::create([
            'employee_id' => 3249, // Your employee ID
            'employee_number' => 'K01122', // Your employee number
            'username' => 'admin',
            'password' => Hash::make('Asuka2025'),
            'is_active' => true,
            'is_admin' => true,
        ]);

        echo "Admin user created!\n";
        echo "Username: admin\n";
        echo "Password: Asuka2025\n";
    }
}
