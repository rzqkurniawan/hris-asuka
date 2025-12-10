<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class HistoryContract extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_history_contract';
    protected $primaryKey = 'history_contract_id';
    public $timestamps = false;

    protected $visible = [
        'history_contract_id',
        'employee_id',
        'employee_grade_id',
        'description',
        'start_date',
        'end_date',
        'start_date_formatted',
        'end_date_formatted',
    ];

    protected $appends = [
        'start_date_formatted',
        'end_date_formatted',
    ];

    protected $with = [
        'employeeGrade',
    ];

    // Relationship to Employee
    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }

    // Relationship to EmployeeGrade
    public function employeeGrade()
    {
        return $this->belongsTo(EmployeeGrade::class, 'employee_grade_id', 'employee_grade_id');
    }

    /**
     * Get formatted start date
     * Format: "dd-mm-yyyy"
     */
    public function getStartDateFormattedAttribute(): string
    {
        if (!$this->start_date) {
            return '-';
        }

        try {
            $date = new \DateTime($this->start_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }

    /**
     * Get formatted end date
     * Format: "dd-mm-yyyy"
     */
    public function getEndDateFormattedAttribute(): string
    {
        if (!$this->end_date) {
            return '-';
        }

        try {
            $date = new \DateTime($this->end_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }
}
