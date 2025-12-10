<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class JobGrade extends Model
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
    protected $table = 'ki_job_grade';

    /**
     * The primary key for the model.
     *
     * @var string
     */
    protected $primaryKey = 'job_grade_id';

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
        'job_grade_id',
        'job_grade_name',
    ];

    /**
     * Get the employees for this job grade
     */
    public function employees()
    {
        return $this->hasMany(Employee::class, 'job_grade_id', 'job_grade_id');
    }
}
