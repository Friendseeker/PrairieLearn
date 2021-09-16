-- BLOCK instance_questions_select_manual_grading_objects

CREATE FUNCTION
    instance_questions_select_manual_grading_objects(
        IN arg_instance_question_id bigint,
        IN arg_user_id bigint,
        IN arg_conflicting_grading_job_id bigint,
        IN arg_manual_grading_expiry text,
        OUT instance_question jsonb,
        OUT question jsonb,
        OUT variant jsonb,
        OUT submission jsonb,
        OUT grading_user jsonb,
        OUT conflict_grading_job jsonb
    )
AS $$
DECLARE
    instance_question_id bigint;
    assessment_question_id bigint;
BEGIN

    SELECT iq.id, iq.assessment_question_id
    INTO instance_question_id, assessment_question_id
    FROM
        instance_questions AS iq
    WHERE
        iq.id = arg_instance_question_id
    FOR UPDATE;

    IF NOT FOUND THEN RAISE EXCEPTION 'instance question not found: %', arg_instance_question_id; END IF;

    PERFORM instance_questions_assign_manual_grading_user(assessment_question_id, instance_question_id, arg_user_id);

    -- conflict df: when TA 'x' and TA 'y' have same manual grading page open at same time and both submit a grade. Second submitter must decide whether first or second grade valid.
    IF arg_conflicting_grading_job_id IS NOT NULL THEN
        SELECT json_build_object('id', gj.id, 'score', gj.score, 'feedback', gj.feedback, 'graded_by', CONCAT(u.name, ' (', u.uid, ')'), 'conflictDataSource', 'grading_job')
        INTO conflict_grading_job
        FROM
            grading_jobs AS gj
            JOIN users AS u ON (u.user_id = gj.auth_user_id)
        WHERE gj.id = arg_conflicting_grading_job_id;
    ELSE
        -- always check if grading conflict needs to be resolved in case second submitter closed browser on conflict resolution view.
        SELECT json_build_object('id', gj.id, 'score', gj.score, 'feedback', gj.feedback, 'graded_by', CONCAT(u.name, ' (', u.uid, ')'), 'conflictDataSource', 'grading_job')
        INTO conflict_grading_job
        FROM
            grading_jobs AS gj
            JOIN submissions AS s ON (s.id = gj.submission_id)
            JOIN variants AS v ON (v.id = s.variant_id)
            JOIN instance_questions AS iq ON (iq.id = v.instance_question_id)
            JOIN users AS u ON (u.user_id = gj.auth_user_id)
        WHERE
            iq.id = arg_instance_question_id
            AND gj.manual_grading_conflict IS TRUE
        LIMIT 1;
    END IF;

    SELECT to_jsonb(iq.*), to_jsonb(q.*), to_jsonb(v.*), to_jsonb(s.*)
    INTO instance_question, question, variant, submission
    FROM
        instance_questions AS iq
        JOIN assessment_questions AS aq ON (aq.id = iq.assessment_question_id)
        JOIN questions AS q ON (q.id = aq.question_id)
        JOIN variants AS v ON (v.instance_question_id = iq.id)
        JOIN submissions AS s ON (s.variant_id = v.id)
    WHERE
        iq.id = arg_instance_question_id
    ORDER BY s.date DESC, s.id DESC
    LIMIT 1;

    -- We need to move the grading_user into a separate query if and only if the submission is 
    IF submission IS NOT NULL THEN
        SELECT to_json(u.*)
        INTO grading_user
        FROM
            instance_questions AS iq
            JOIN variants AS v ON (v.instance_question_id = iq.id)
            JOIN submissions AS s ON (s.variant_id = v.id)
            JOIN users_manual_grading AS umg ON (iq.id = umg.instance_question_id)
            JOIN users AS u ON (u.user_id = umg.user_id)
            LEFT JOIN grading_jobs AS gj ON (s.id = gj.submission_id)
        WHERE 
            iq.id = arg_instance_question_id
            AND
            -- We want to display auth user for when grade was submitted, as manual grading user is flushed due to manual grading expiry time
            ( -- we want instance questions with conflicts
                gj.manual_grading_conflict IS TRUE
                OR
                (umg.date_started >= (NOW() - arg_manual_grading_expiry::interval))
            )
            ORDER BY umg.date_started ASC
            LIMIT 1;
    END IF;

END;
$$ LANGUAGE plpgsql VOLATILE;
