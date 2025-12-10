<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Religion extends Model
{
    use HasFactory;

    protected $connection = 'c3ais';
    protected $table = 'ki_religion';
    protected $primaryKey = 'religion_id';
    public $timestamps = false;

    protected $visible = [
        'religion_id',
        'religion_name',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class, 'religion_id', 'religion_id');
    }
}
