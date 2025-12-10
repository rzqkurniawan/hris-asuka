<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CompanyWorkbase extends Model
{
    use HasFactory;

    protected $connection = 'c3ais';
    protected $table = 'ki_company_workbase';
    protected $primaryKey = 'company_workbase_id';
    public $timestamps = false;

    protected $visible = [
        'company_workbase_id',
        'company_workbase_name',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class, 'company_workbase_id', 'company_workbase_id');
    }
}
