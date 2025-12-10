<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class FamilyType extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_family_type';
    protected $primaryKey = 'family_type_id';
    public $timestamps = false;

    protected $visible = [
        'family_type_id',
        'family_type_name',
        'description',
    ];

    public function employeeFamilies()
    {
        return $this->hasMany(EmployeeFamily::class, 'family_type_id', 'family_type_id');
    }
}
