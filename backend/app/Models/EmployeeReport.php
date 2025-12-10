<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class EmployeeReport extends Model
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
    protected $table = 'ki_employee_report';

    /**
     * The primary key for the model.
     *
     * @var string
     */
    protected $primaryKey = 'employee_report_id';

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
        'employee_report_id',
        'month_year',
        'employee_number',
        'moneybox',
    ];

    /**
     * Get the employee for this report
     */
    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_number', 'employee_number');
    }
}
