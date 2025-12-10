<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class JobOrder extends Model
{
    use HasFactory;

    protected $connection = 'c3ais';
    protected $table = 'ki_job_order';
    protected $primaryKey = 'job_order_id';
    public $timestamps = false;

    protected $visible = [
        'job_order_id',
        'job_order_number',
        'job_order_description',
    ];

    public function employees()
    {
        return $this->hasMany(Employee::class, 'job_order_id', 'job_order_id');
    }
}
