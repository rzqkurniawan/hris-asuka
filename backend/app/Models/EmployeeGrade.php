<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeeGrade extends Model
{
    use HasFactory;

    protected $connection = 'c3ais';
    protected $table = 'ki_employee_grade';
    protected $primaryKey = 'employee_grade_id';
    public $timestamps = false;

    protected $visible = [
        'employee_grade_id',
        'employee_grade_name',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class, 'employee_grade_id', 'employee_grade_id');
    }
}
