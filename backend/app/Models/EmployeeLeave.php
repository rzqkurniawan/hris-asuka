<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmployeeLeave extends Model
{
    protected $connection = 'c3ais_write';
    protected $table = 'ki_employee_leave';
    protected $primaryKey = 'employee_leave_id';
    public $timestamps = false;

    protected $fillable = [
        'employee_leave_number',
        'employee_id',
        'leave_category_id',
        'start_leave',
        'date_leave',
        'proposed_date',
        'approved_date',
        'work_date',
        'date_begin',
        'date_end',
        'date_extended',
        'notes',
        'address_leave',
        'phone_leave',
        'subtitute_on_leave',
        'is_approved',
        'approved_by',
        'status',
        'sisa_cuti',
        'created_by',
        'created_date',
        'modified_by',
        'modified_date',
        'processed_by',
        'processed_date',
        'approver',
        'approver_date',
    ];

    protected $casts = [
        'employee_id' => 'integer',
        'leave_category_id' => 'integer',
        'start_leave' => 'date',
        'date_leave' => 'date',
        'proposed_date' => 'date',
        'approved_date' => 'date',
        'work_date' => 'date',
        'date_begin' => 'date',
        'date_end' => 'date',
        'date_extended' => 'date',
        'subtitute_on_leave' => 'integer',
        'is_approved' => 'boolean',
        'approved_by' => 'integer',
        'sisa_cuti' => 'integer',
        'created_by' => 'integer',
        'created_date' => 'datetime',
        'modified_by' => 'integer',
        'modified_date' => 'datetime',
        'processed_by' => 'integer',
        'processed_date' => 'datetime',
        'approver' => 'integer',
        'approver_date' => 'datetime',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id')
                    ->setConnection('c3ais');
    }

    public function leaveCategory()
    {
        return $this->belongsTo(LeaveCategory::class, 'leave_category_id', 'leave_category_id')
                    ->setConnection('c3ais');
    }

    public function substitute()
    {
        return $this->belongsTo(Employee::class, 'subtitute_on_leave', 'employee_id')
                    ->setConnection('c3ais');
    }

    public function approverEmployee()
    {
        return $this->belongsTo(Employee::class, 'approved_by', 'employee_id')
                    ->setConnection('c3ais');
    }
}
