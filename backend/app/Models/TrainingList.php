<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TrainingList extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_training_list';
    protected $primaryKey = 'training_id';
    public $timestamps = false;

    protected $visible = [
        'training_id',
        'training_name',
        'employee_id',
        'training_type',
        'description',
        'place',
        'provider',
        'duration_day',
        'hours',
        'evaluation_date',
        'start_date',
        'end_date',
        'start_date_formatted',
        'end_date_formatted',
        'evaluation_date_formatted',
    ];

    protected $appends = [
        'start_date_formatted',
        'end_date_formatted',
        'evaluation_date_formatted',
    ];

    // Relationship to Employee
    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
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

    /**
     * Get formatted evaluation date
     * Format: "dd-mm-yyyy"
     */
    public function getEvaluationDateFormattedAttribute(): string
    {
        if (!$this->evaluation_date) {
            return '-';
        }

        try {
            $date = new \DateTime($this->evaluation_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }
}
