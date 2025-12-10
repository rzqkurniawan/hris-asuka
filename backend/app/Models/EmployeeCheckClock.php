<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EmployeeCheckClock extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_employee_check_clock';
    protected $primaryKey = 'employee_check_clock_id';
    public $timestamps = false;

    protected $visible = [
        'employee_check_clock_id',
        'employee_check_id',
        'date_check_clock',
        'on_duty',
        'off_duty',
        'check_in',
        'check_out',
        'emergency_call',
        'start_call',
        'end_call',
        'no_lunch',
        'description',
        'note_for_shift',
        'shift_category',
        'type_work_hour',
        'permission_late',
        'job_order_id',
        'daily_wages',
        'date_check_clock_formatted',
        'on_duty_formatted',
        'off_duty_formatted',
        'check_in_formatted',
        'check_out_formatted',
        'start_call_formatted',
        'end_call_formatted',
        'day_name',
        'is_weekend',
        'emergency_call_boolean',
        'no_lunch_boolean',
        'permission_late_boolean',
    ];

    protected $appends = [
        'date_check_clock_formatted',
        'on_duty_formatted',
        'off_duty_formatted',
        'check_in_formatted',
        'check_out_formatted',
        'start_call_formatted',
        'end_call_formatted',
        'day_name',
        'is_weekend',
        'emergency_call_boolean',
        'no_lunch_boolean',
        'permission_late_boolean',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_check_id', 'employee_check_id');
    }

    public function overtimeDetails()
    {
    return $this->hasMany(OvertimeWorkorderDetail::class, 'employee_id', 'employee_check_id')
        ->whereDate('overtime_date', '=', $this->date_check_clock);
    }

    public function jobOrder()
    {
        return $this->belongsTo(JobOrder::class, 'job_order_id', 'job_order_id');
    }

    // Date formatted
    public function getDateCheckClockFormattedAttribute(): string
    {
        if (!$this->date_check_clock) {
            return '-';
        }
        try {
            $date = new \DateTime($this->date_check_clock);
            return $date->format('d/m/Y');
        } catch (\Exception $e) {
            return '-';
        }
    }

    // On Duty formatted
    public function getOnDutyFormattedAttribute(): string
    {
        if (!$this->on_duty || $this->on_duty == '00:00:00') {
            return '-';
        }
        try {
            $time = new \DateTime($this->on_duty);
            return $time->format('H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    // Off Duty formatted
    public function getOffDutyFormattedAttribute(): string
    {
        if (!$this->off_duty || $this->off_duty == '00:00:00') {
            return '-';
        }
        try {
            $time = new \DateTime($this->off_duty);
            return $time->format('H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    // Check In formatted
    public function getCheckInFormattedAttribute(): string
    {
        if (!$this->check_in || $this->check_in == '00:00:00') {
            return '-';
        }
        try {
            $time = new \DateTime($this->check_in);
            return $time->format('H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    // Check Out formatted
    public function getCheckOutFormattedAttribute(): string
    {
        if (!$this->check_out || $this->check_out == '00:00:00') {
            return '-';
        }
        try {
            $time = new \DateTime($this->check_out);
            return $time->format('H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    // Start Call formatted
    public function getStartCallFormattedAttribute(): string
    {
        if (!$this->start_call || $this->start_call == '00:00:00') {
            return '-';
        }
        try {
            $time = new \DateTime($this->start_call);
            return $time->format('H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    // End Call formatted
    public function getEndCallFormattedAttribute(): string
    {
        if (!$this->end_call || $this->end_call == '00:00:00') {
            return '-';
        }
        try {
            $time = new \DateTime($this->end_call);
            return $time->format('H:i');
        } catch (\Exception $e) {
            return '-';
        }
    }

    // Day name in Indonesian
    public function getDayNameAttribute(): string
    {
        if (!$this->date_check_clock) {
            return '-';
        }
        try {
            $date = new \DateTime($this->date_check_clock);
            $dayNames = [
                'Sunday' => 'Minggu',
                'Monday' => 'Senin',
                'Tuesday' => 'Selasa',
                'Wednesday' => 'Rabu',
                'Thursday' => 'Kamis',
                'Friday' => 'Jumat',
                'Saturday' => 'Sabtu',
            ];
            $dayName = $date->format('l');
            return $dayNames[$dayName] ?? $dayName;
        } catch (\Exception $e) {
            return '-';
        }
    }

    // Check if weekend
    public function getIsWeekendAttribute(): bool
    {
        if (!$this->date_check_clock) {
            return false;
        }
        try {
            $date = new \DateTime($this->date_check_clock);
            $dayOfWeek = $date->format('w'); // 0 (Sunday) to 6 (Saturday)
            return $dayOfWeek == 0 || $dayOfWeek == 6;
        } catch (\Exception $e) {
            return false;
        }
    }

    // Convert emergency_call varchar to boolean
    public function getEmergencyCallBooleanAttribute(): bool
    {
        return strtolower($this->emergency_call) === 'ya' || $this->emergency_call === 'Yes';
    }

    // Convert no_lunch varchar to boolean
    public function getNoLunchBooleanAttribute(): bool
    {
        return strtolower($this->no_lunch) === 'ya' || $this->no_lunch === 'Yes';
    }

    // Convert permission_late varchar to boolean
    public function getPermissionLateBooleanAttribute(): bool
    {
        // Assuming '1' or 'Ya' means has permission, '2' or 'Tidak' means no permission
        return $this->permission_late == '1' || strtolower($this->permission_late) === 'ya';
    }

    /**
     * Computed holiday notes based on weekend overtime logic
     * If weekend and has check in/out, it's considered overtime
     */
    public function getComputedHolidayNotesAttribute(): string
    {
        $isWeekend = $this->is_weekend;
        $hasCheckIn = $this->check_in_formatted != '-';
        $hasCheckOut = $this->check_out_formatted != '-';

        if ($isWeekend && $hasCheckIn && $hasCheckOut) {
            return 'LIBUR/OT';
        }

        return $this->description ?? '-';
    }
}
