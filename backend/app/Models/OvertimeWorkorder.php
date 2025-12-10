<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OvertimeWorkorder extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_overtime_workorder';
    protected $primaryKey = 'overtime_workorder_id';
    public $timestamps = false;

    protected $visible = [
        'overtime_workorder_id',
        'overtime_workorder_number',
        'proposed_date',
        'work_description',
        'work_location',
        'job_order_id',
        'department_id',
        'requested_id',
        'approval1_by',
        'approval1_date',
        'approval2_by',
        'approval2_date',
        'verified_by',
        'verified_date',
        'proposed_date_formatted',
        'approval1_date_formatted',
        'approval2_date_formatted',
        'verified_date_formatted',
    ];

    protected $appends = [
        'proposed_date_formatted',
        'approval1_date_formatted',
        'approval2_date_formatted',
        'verified_date_formatted',
    ];

    public function jobOrder()
    {
        return $this->belongsTo(JobOrder::class, 'job_order_id', 'job_order_id');
    }

    public function department()
    {
        return $this->belongsTo(Department::class, 'department_id', 'department_id');
    }

    public function companyWorkbase()
    {
        return $this->belongsTo(CompanyWorkbase::class, 'work_location', 'company_workbase_id');
    }

    public function requestedBy()
    {
        return $this->belongsTo(Employee::class, 'requested_id', 'employee_id');
    }

    public function approval1By()
    {
        return $this->belongsTo(C3aisUser::class, 'approval1_by', 'user_id');
    }

    public function approval2By()
    {
        return $this->belongsTo(C3aisUser::class, 'approval2_by', 'user_id');
    }

    public function verifiedBy()
    {
        return $this->belongsTo(C3aisUser::class, 'verified_by', 'user_id');
    }

    public function details()
    {
        return $this->hasMany(OvertimeWorkorderDetail::class, 'overtime_workorder_id', 'overtime_workorder_id');
    }

    public function getProposedDateFormattedAttribute(): string
    {
        if (!$this->proposed_date) {
            return '-';
        }
        try {
            $date = new \DateTime($this->proposed_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }

    public function getApproval1DateFormattedAttribute(): string
    {
        if (!$this->approval1_date) {
            return '-';
        }
        try {
            $date = new \DateTime($this->approval1_date);
            return $date->format('d-m-Y H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    public function getApproval2DateFormattedAttribute(): string
    {
        if (!$this->approval2_date) {
            return '-';
        }
        try {
            $date = new \DateTime($this->approval2_date);
            return $date->format('d-m-Y H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    public function getVerifiedDateFormattedAttribute(): string
    {
        if (!$this->verified_date) {
            return '-';
        }
        try {
            $date = new \DateTime($this->verified_date);
            return $date->format('d-m-Y H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }
}
