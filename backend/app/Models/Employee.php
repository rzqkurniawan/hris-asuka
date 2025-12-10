<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Employee extends Model
{
    use HasFactory;

    /**
     * The connection name for the model.
     * This connects to c3ais database on Google Cloud
     *
     * @var string
     */
    protected $connection = 'c3ais';

    /**
     * The table associated with the model.
     *
     * @var string
     */
    protected $table = 'ki_employee';

    /**
     * The primary key for the model.
     *
     * @var string
     */
    protected $primaryKey = 'employee_id';

    /**
     * The "type" of the primary key ID.
     *
     * @var string
     */
    protected $keyType = 'int';

    /**
     * Indicates if the IDs are auto-incrementing.
     *
     * @var bool
     */
    public $incrementing = true;

    /**
     * Indicates if the model should be timestamped.
     *
     * @var bool
     */
    public $timestamps = false;

    /**
     * The attributes that should be visible for serialization.
     *
     * @var array<int, string>
     */
    protected $visible = [
        'employee_id',
        'employee_number',
        'fullname',
        'nickname',
        'gender',
        'blood_group',
        'place_birthday',
        'birthday',
        'religion_id',
        'marital_status_id',
        'address',
        'sin_num',
        'identity_file_name',
        'mobile_phone',
        'email1',
        'npwp',
        'bpjs_health_number',
        'social_security_number',
        'job_grade_id',
        'employee_grade_id',
        'department_id',
        'job_order_id',
        'company_workbase_id',
        'employee_status_id',
        'working_status',
        'join_date',
        'employment_date',
        'come_out_date',
        'termination_date',
        'termination_reason',
        'notes',
        'is_active',
    ];

    /**
     * The relationships that should always be loaded.
     *
     * @var array<int, string>
     */
    protected $with = [
        'jobGrade',
        'religion',
        'maritalStatus',
        'employeeGrade',
        'department',
        'jobOrder',
        'companyWorkbase',
        'employeeStatus',
    ];

    /**
     * Get the user credential for this employee
     * Note: User table is in local database, not c3ais
     */
    public function user()
    {
        return $this->hasOne(User::class, 'employee_id', 'employee_id');
    }

    /**
     * Get the job grade for this employee
     */
    public function jobGrade()
    {
        return $this->belongsTo(JobGrade::class, 'job_grade_id', 'job_grade_id');
    }

    /**
     * Get the religion for this employee
     */
    public function religion()
    {
        return $this->belongsTo(Religion::class, 'religion_id', 'religion_id');
    }

    /**
     * Get the marital status for this employee
     */
    public function maritalStatus()
    {
        return $this->belongsTo(MaritalStatus::class, 'marital_status_id', 'marital_status_id');
    }

    /**
     * Get the employee grade for this employee
     */
    public function employeeGrade()
    {
        return $this->belongsTo(EmployeeGrade::class, 'employee_grade_id', 'employee_grade_id');
    }

    /**
     * Get the department for this employee
     */
    public function department()
    {
        return $this->belongsTo(Department::class, 'department_id', 'department_id');
    }

    /**
     * Get the job order for this employee
     */
    public function jobOrder()
    {
        return $this->belongsTo(JobOrder::class, 'job_order_id', 'job_order_id');
    }

    /**
     * Get the company workbase for this employee
     */
    public function companyWorkbase()
    {
        return $this->belongsTo(CompanyWorkbase::class, 'company_workbase_id', 'company_workbase_id');
    }

    /**
     * Get the employee status for this employee
     */
    public function employeeStatus()
    {
        return $this->belongsTo(EmployeeStatus::class, 'employee_status_id', 'employee_status_id');
    }

    /**
     * Get all employee reports (for moneybox history)
     */
    public function reports()
    {
        return $this->hasMany(EmployeeReport::class, 'employee_number', 'employee_number');
    }

    /**
     * Get all family members for this employee
     */
    public function families()
    {
        return $this->hasMany(EmployeeFamily::class, 'employee_id', 'employee_id');
    }

    /**
     * Get all contract history for this employee
     */
    public function historyContracts()
    {
        return $this->hasMany(HistoryContract::class, 'employee_id', 'employee_id')
            ->orderBy('start_date', 'desc');
    }

    /**
     * Get all training history for this employee
     */
    public function trainings()
    {
        return $this->hasMany(TrainingList::class, 'employee_id', 'employee_id')
            ->orderBy('start_date', 'desc');
    }

    /**
     * Get all work experience for this employee
     */
    public function workExperiences()
    {
        return $this->hasMany(WorkExperience::class, 'employee_id', 'employee_id')
            ->orderBy('start_date', 'desc');
    }

    /**
     * Get all education history for this employee
     */
    public function educations()
    {
        return $this->hasMany(EmployeeEducation::class, 'employee_id', 'employee_id')
            ->orderBy('education_end', 'desc');
    }

    /**
     * Calculate working period from join_date to now
     * Returns format: "6Y 4M"
     */
    public function getWorkingPeriodAttribute(): string
    {
        if (!$this->join_date) {
            return '0Y 0M';
        }

        $start = new \DateTime($this->join_date);
        $now = new \DateTime();
        $interval = $start->diff($now);

        $years = $interval->y;
        $months = $interval->m;

        return "{$years}Y {$months}M";
    }

    /**
     * Get total moneybox amount from all reports (SUM)
     * Returns formatted string: "Rp 7.700.000"
     */
    public function getInvestmentAmountAttribute(): string
    {
        // SUM all moneybox from ki_employee_report
        $totalMoneybox = \DB::connection('c3ais')
            ->table('ki_employee_report')
            ->where('employee_id', $this->employee_id)
            ->sum('moneybox');

        if ($totalMoneybox == 0) {
            return 'Rp 0';
        }

        return 'Rp ' . number_format($totalMoneybox, 0, ',', '.');
    }

    /**
     * Get gender display string
     * 1 = Laki-laki, 2 = Perempuan
     */
    public function getGenderDisplayAttribute(): string
    {
        if (!$this->gender) {
            return '-';
        }

        return $this->gender == 1 ? 'Laki-laki' : 'Perempuan';
    }

    /**
     * Get formatted place and date of birth
     * Format: "Gresik, 27 Juni 2000"
     */
    public function getPlaceDateBirthAttribute(): string
    {
        if (!$this->place_birthday || !$this->birthday) {
            return '-';
        }

        $months = [
            1 => 'Januari',
            2 => 'Februari',
            3 => 'Maret',
            4 => 'April',
            5 => 'Mei',
            6 => 'Juni',
            7 => 'Juli',
            8 => 'Agustus',
            9 => 'September',
            10 => 'Oktober',
            11 => 'November',
            12 => 'Desember'
        ];

        $date = new \DateTime($this->birthday);
        $day = $date->format('d');
        $month = $months[(int)$date->format('m')];
        $year = $date->format('Y');

        return "{$this->place_birthday}, {$day} {$month} {$year}";
    }

    /**
     * Get job order display string
     * Format: "JO-HRD-2501-0010 - Internal Expense HRD & GA Department 2025"
     */
    public function getJobOrderDisplayAttribute(): string
    {
        if (!$this->jobOrder) {
            return '-';
        }

        return "{$this->jobOrder->job_order_number} - {$this->jobOrder->job_order_description}";
    }

    /**
     * Get formatted join date
     * Format: "dd-mm-yyyy"
     */
    public function getJoinDateFormattedAttribute(): string
    {
        if (!$this->join_date) {
            return '-';
        }

        try {
            $date = new \DateTime($this->join_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }

    /**
     * Get formatted employment date (Appointed)
     * Format: "dd-mm-yyyy"
     */
    public function getEmploymentDateFormattedAttribute(): string
    {
        if (!$this->employment_date) {
            return '-';
        }

        try {
            $date = new \DateTime($this->employment_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }

    /**
     * Get formatted come out date (Leaving)
     * Format: "dd-mm-yyyy"
     */
    public function getComeOutDateFormattedAttribute(): string
    {
        if (!$this->come_out_date) {
            return '-';
        }

        try {
            $date = new \DateTime($this->come_out_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }

    /**
     * Get formatted termination date
     * Format: "dd-mm-yyyy"
     */
    public function getTerminationDateFormattedAttribute(): string
    {
        if (!$this->termination_date) {
            return '-';
        }

        try {
            $date = new \DateTime($this->termination_date);
            return $date->format('d-m-Y');
        } catch (\Exception $e) {
            return '-';
        }
    }

    /**
     * Get is_active display string
     * 1 = Ya, 2 = Tidak
     */
    public function getIsActiveDisplayAttribute(): string
    {
        if (!$this->is_active) {
            return '-';
        }

        return $this->is_active == 1 ? 'Ya' : 'Tidak';
    }

    /**
     * Check if employee already has user account
     */
    public function hasUserAccount(): bool
    {
        // Query local database directly
        return \DB::connection('mysql')
            ->table('users')
            ->where('employee_id', $this->employee_id)
            ->exists();
    }
}
