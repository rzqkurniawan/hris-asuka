<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LeaveCategory extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_leave_category';
    protected $primaryKey = 'leave_category_id';
    public $timestamps = false;

    protected $fillable = [
        'leave_category_name',
        'minimal_unit',
        'unit',
        'report_symbol',
        'hex_color',
        'is_active',
        'is_deduct',
    ];

    protected $casts = [
        'minimal_unit' => 'integer',
        'unit' => 'integer',
        'is_active' => 'boolean',
        'is_deduct' => 'boolean',
    ];

    public function employeeLeaves()
    {
        return $this->hasMany(EmployeeLeave::class, 'leave_category_id', 'leave_category_id');
    }
}
