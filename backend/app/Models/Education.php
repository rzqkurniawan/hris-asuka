<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Education extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_education';
    protected $primaryKey = 'education_id';
    public $timestamps = false;

    protected $visible = [
        'education_id',
        'education_name',
        'description',
    ];

    public function employeeEducations()
    {
        return $this->hasMany(EmployeeEducation::class, 'education_id', 'education_id');
    }
}
