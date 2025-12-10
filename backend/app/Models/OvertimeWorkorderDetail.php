<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OvertimeWorkorderDetail extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_overtime_workorder_detail';
    protected $primaryKey = 'otwo_detail_id';
    public $timestamps = false;

    protected $visible = [
        'otwo_detail_id',
        'overtime_workorder_id',
        'employee_id',
        'overtime_date',
        'description',
        'start_time',
        'finish_time',
        'approval_status1',
        'approval_status2',
        'overtime_date_formatted',
        'start_time_formatted',
        'finish_time_formatted',
    ];

    protected $appends = [
        'overtime_date_formatted',
        'start_time_formatted',
        'finish_time_formatted',
    ];

    public function overtimeWorkorder()
    {
        return $this->belongsTo(OvertimeWorkorder::class, 'overtime_workorder_id', 'overtime_workorder_id');
    }

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }

    public function getOvertimeDateFormattedAttribute(): string
    {
        if (!$this->overtime_date) {
            return '-';
        }
        try {
            $date = new \DateTime($this->overtime_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }

    public function getStartTimeFormattedAttribute(): string
    {
        if (!$this->start_time) {
            return '-';
        }
        try {
            $time = new \DateTime($this->start_time);
            return $time->format('H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    public function getFinishTimeFormattedAttribute(): string
    {
        if (!$this->finish_time) {
            return '-';
        }
        try {
            $time = new \DateTime($this->finish_time);
            return $time->format('H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }
}
