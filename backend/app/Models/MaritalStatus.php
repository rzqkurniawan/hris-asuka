<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MaritalStatus extends Model
{
    use HasFactory;

    protected $connection = 'c3ais';
    protected $table = 'ki_marital_status';
    protected $primaryKey = 'marital_status_id';
    public $timestamps = false;

    protected $visible = [
        'marital_status_id',
        'marital_status_name',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class, 'marital_status_id', 'marital_status_id');
    }
}
