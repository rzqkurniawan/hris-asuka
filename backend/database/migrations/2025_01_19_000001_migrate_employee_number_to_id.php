<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Map existing employee_number to employee_id from c3ais database
     */
    public function up(): void
    {
        // Get all users with employee_number
        $users = DB::connection('mysql')
            ->table('users')
            ->select('id', 'employee_number')
            ->whereNotNull('employee_number')
            ->get();

        foreach ($users as $user) {
            // Get employee_id from c3ais database based on employee_number
            $employee = DB::connection('c3ais')
                ->table('ki_employee')
                ->select('employee_id')
                ->where('employee_number', $user->employee_number)
                ->first();

            if ($employee) {
                // Update user with employee_id
                DB::connection('mysql')
                    ->table('users')
                    ->where('id', $user->id)
                    ->update(['employee_id' => $employee->employee_id]);
            } else {
                // Log warning if employee not found
                echo "WARNING: Employee not found for employee_number: {$user->employee_number}\n";
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Set all employee_id to null
        DB::connection('mysql')
            ->table('users')
            ->update(['employee_id' => null]);
    }
};
