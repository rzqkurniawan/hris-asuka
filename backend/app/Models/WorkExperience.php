<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WorkExperience extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_work_experience';
    protected $primaryKey = 'experience_id';
    public $timestamps = false;

    protected $visible = [
        'experience_id',
        'employee_id',
        'experience_description',
        'experience_position',
        'start_date',
        'end_date',
        'start_date_formatted',
        'end_date_formatted',
    ];

    protected $appends = [
        'start_date_formatted',
        'end_date_formatted',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }

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
