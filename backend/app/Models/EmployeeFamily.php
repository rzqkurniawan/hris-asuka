<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmployeeFamily extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_employees_family';
    protected $primaryKey = 'employee_family_id';
    public $timestamps = false;

    protected $visible = [
        'employee_family_id',
        'employee_id',
        'family_type_id',
        'family_name',
        'gender',
        'city_of_brith',
        'birthday',
        'last_education',
        'job',
        'notes',
        'birth_date_formatted',
    ];

    protected $with = [
        'familyType',
        'education',
    ];

    protected $appends = [
        'birth_date_formatted',
    ];

    // Relationships
    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }

    public function familyType()
    {
        return $this->belongsTo(FamilyType::class, 'family_type_id', 'family_type_id');
    }

    public function education()
    {
        return $this->belongsTo(Education::class, 'last_education', 'education_id');
    }

    // Accessor for formatted birth date
    public function getBirthDateFormattedAttribute(): string
    {
        if (!$this->city_of_brith || !$this->birthday) {
            return '-';
        }

        $months = [
            1 => 'Januari', 2 => 'Februari', 3 => 'Maret', 4 => 'April',
            5 => 'Mei', 6 => 'Juni', 7 => 'Juli', 8 => 'Agustus',
            9 => 'September', 10 => 'Oktober', 11 => 'November', 12 => 'Desember'
        ];

        try {
            $date = new \DateTime($this->birthday);
            $day = $date->format('d');
            $month = $months[(int)$date->format('m')];
            $year = $date->format('Y');

            return "{$this->city_of_brith}, {$day} {$month} {$year}";
        } catch (\Exception $e) {
            return '-';
        }
    }
}
