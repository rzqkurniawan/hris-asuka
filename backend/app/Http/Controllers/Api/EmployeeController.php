<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class EmployeeController extends Controller
{
    /**
     * Get complete employee data for authenticated user
     * Used in employee_data_screen
     */
    public function getEmployeeData(Request $request)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Personal Data
            $personalData = [
                'fullname' => $employee->fullname ?? '-',
                'nickname' => $employee->nickname ?? '-',
                'gender' => $employee->gender_display,
                'blood_type' => $employee->blood_group ?? '-',
                'place_date_birth' => $employee->place_date_birth,
                'religion' => $employee->religion ? $employee->religion->religion_name : '-',
                'marital_status' => $employee->maritalStatus ? $employee->maritalStatus->marital_status_name : '-',
                'address' => $employee->address ?? '-',
                'nik' => $employee->sin_num ?? '-',
                'identity_file' => $employee->identity_file_name ?? null,
                'mobile_phone' => $employee->mobile_phone ?? '-',
                'email' => $employee->email1 ?? '-',
                'npwp' => $employee->npwp ?? '-',
                'bpjs_health' => $employee->bpjs_health_number ?? '-',
                'bpjs_employment' => $employee->social_security_number ?? '-',
            ];

            // Employment Data
            $employmentData = [
                'employee_number' => $employee->employee_number ?? '-',
                'job_title' => $employee->jobGrade ? $employee->jobGrade->job_grade_name : '-',
                'employee_grade' => $employee->employeeGrade ? $employee->employeeGrade->employee_grade_name : '-',
                'department' => $employee->department ? $employee->department->department_name : '-',
                'job_order' => $employee->job_order_display,
                'workbase' => $employee->companyWorkbase ? $employee->companyWorkbase->company_workbase_name : '-',
                'employee_status' => $employee->employeeStatus ? $employee->employeeStatus->employee_status : '-',
                'working_status' => $employee->working_status ?? '-',
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'personal_data' => $personalData,
                    'employment_data' => $employmentData,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch employee data',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get family data for authenticated user
     * Used in family_data_screen
     */
    public function getFamilyData(Request $request)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get all family members with relationships
            $families = $employee->families;

            // Format family data
            $familyData = $families->map(function ($family) {
                return [
                    'name' => $family->family_name ?? '-',
                    'relationship' => $family->familyType ? $family->familyType->family_type_name : '-',
                    'birth_date' => $family->birth_date_formatted,
                    'gender' => $family->gender ?? '-',
                    'education' => $family->education ? $family->education->education_name : '-',
                    'job' => $family->job ?? '-',
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'family_count' => $families->count(),
                    'families' => $familyData,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch family data',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get position history for authenticated user
     * Used in position_history_screen
     */
    public function getPositionHistory(Request $request)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get all contract history
            $contracts = $employee->historyContracts;

            // Get latest contract end date
            $latestEndDate = '-';
            if ($contracts->count() > 0) {
                $latestContract = $contracts->first(); // Already ordered by start_date desc
                $latestEndDate = $latestContract->end_date_formatted;
            }

            // Work History Info
            $workHistory = [
                'start_of_work' => $employee->join_date_formatted,
                'appointed' => $employee->employment_date_formatted,
                'end_of_work' => $latestEndDate,
                'leaving' => $employee->come_out_date_formatted,
                'reason_for_leaving' => $employee->termination_reason ?? '-',
            ];

            // Contract History List
            $contractHistory = $contracts->map(function ($contract, $index) {
                return [
                    'no' => $index + 1,
                    'description' => $contract->description ?? '-',
                    'grade' => $contract->employeeGrade ? $contract->employeeGrade->employee_grade_name : '-',
                    'in_date' => $contract->start_date_formatted,
                    'out_date' => $contract->end_date_formatted,
                ];
            });

            // Remarks
            $remarks = [
                'salary' => $employee->is_active_display,
                'notes' => $employee->notes ?? '-',
            ];

            return response()->json([
                'success' => true,
                'data' => [
                    'work_history' => $workHistory,
                    'contract_history' => $contractHistory,
                    'remarks' => $remarks,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch position history',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get training history for authenticated user
     * Used in training_history_screen
     */
    public function getTrainingHistory(Request $request)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get all training history
            $trainings = $employee->trainings;

            // Format training data
            $trainingData = $trainings->map(function ($training) {
                return [
                    'name' => $training->training_name ?? '-',
                    'place' => $training->place ?? '-',
                    'provider' => $training->provider ?? '-',
                    'start_date' => $training->start_date_formatted,
                    'end_date' => $training->end_date_formatted,
                    'duration_days' => $training->duration_day ?? 0,
                    'evaluation_date' => $training->evaluation_date_formatted,
                    'notes' => $training->description ?? '-',
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'training_count' => $trainings->count(),
                    'trainings' => $trainingData,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch training history',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get work experience for authenticated user
     * Used in work_experience_screen
     */
    public function getWorkExperience(Request $request)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get all work experience
            $experiences = $employee->workExperiences;

            // Format work experience data
            $experienceData = $experiences->map(function ($experience) {
                return [
                    'company' => $experience->experience_description ?? '-',
                    'position' => $experience->experience_position ?? '-',
                    'start_date' => $experience->start_date_formatted,
                    'end_date' => $experience->end_date_formatted,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'experience_count' => $experiences->count(),
                    'experiences' => $experienceData,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch work experience',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Get education history for authenticated user
     * Used in educational_history_screen
     */
    public function getEducationHistory(Request $request)
    {
        try {
            $user = $request->user();
            $employee = $user->employee;

            if (!$employee) {
                return response()->json([
                    'success' => false,
                    'message' => 'Employee data not found',
                ], 404);
            }

            // Get all education history with education relationship
            $educations = $employee->educations()->with('education')->get();

            // Format education data
            $educationData = $educations->map(function ($edu) {
                return [
                    'education' => $edu->education ? $edu->education->education_name : '-',
                    'school_name' => $edu->school_name ?? '-',
                    'major' => $edu->major ?? '',
                    'year_of_entry' => $edu->education_start ? (int)$edu->education_start : 0,
                    'year_of_graduation' => $edu->education_end ? (int)$edu->education_end : 0,
                ];
            });

            return response()->json([
                'success' => true,
                'data' => [
                    'education_count' => $educations->count(),
                    'educations' => $educationData,
                ],
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Failed to fetch education history',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
