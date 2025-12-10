<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeeStatus extends Model
{
    use HasFactory;

    protected $connection = 'c3ais';
    protected $table = 'ki_employee_status';
    protected $primaryKey = 'employee_status_id';
    public $timestamps = false;

    protected $visible = [
        'employee_status_id',
        'employee_status',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class, 'employee_status_id', 'employee_status_id');
    }
}
