<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Department extends Model
{
    use HasFactory;

    protected $connection = 'c3ais';
    protected $table = 'ki_department';
    protected $primaryKey = 'department_id';
    public $timestamps = false;

    protected $visible = [
        'department_id',
        'department_name',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class, 'department_id', 'department_id');
    }
}
