<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmployeeEducation extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_employee_education';
    protected $primaryKey = 'employee_education_id';
    public $timestamps = false;

    protected $visible = [
        'employee_education_id',
        'employee_id',
        'education_id',
        'school_name',
        'education_start',
        'education_end',
        'major',
        'address',
        'city',
        'province',
        'country',
        'is_highest',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }

    public function education()
    {
        return $this->belongsTo(Education::class, 'education_id', 'education_id');
    }
}
