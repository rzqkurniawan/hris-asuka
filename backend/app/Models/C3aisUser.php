<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class C3aisUser extends Model
{
    protected $connection = 'c3ais';
    protected $table = 'ki_user';
    protected $primaryKey = 'user_id';
    public $timestamps = false;

    protected $visible = [
        'user_id',
        'employee_id',
        'user_name',
        'user_displayname',
        'email',
        'user_enabled',
    ];

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id', 'employee_id');
    }
}
