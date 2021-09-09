# Manual Grading

Prairie Learn supports two manual grading features: an interactive UI and a manual grading CSV upload.

A question configured for manual grading allows a student to submit an answer to a question that is marked by a manual grading user, such as an instructor or TA, at a later time.

## Configuring a Question for Manual Grading

Both the interactive UI and CSV upload manual grading features can be configured by adding the "Manual" grading method to a question configuration. It can optionally be combined with other grading methods:

```json
{
    "uuid": "cbf5cbf2-6458-4f13-a418-aa4d2b1093ff",
    "gradingMethods": ["Manual", "Internal"],
    "singleVariant": true,
    ...
}
```

Note that the deprecated `gradingMethod` (singular) only supports a single grading method in the question configuration. The `gradingMethods` (plural) supports an array that can include all three grading methods.

It is recommended to also mark manually-graded questions as `"singleVariant": true`, even on Homework assessments, so that students are only given a single random variant. This may not be beneficial on questions that include "Internal" or "External" grading methods with the "Manual" grading method, as one may desire multiple variants to be produced.

## "Save" / "Save & Grade" Actions

The "Save" and "Save & Grade" actions appear as buttons on a question. A student clicks each button to either save or grade an answer. Each button will be available to a student based on the grading method configuration of a question. Here are the following configuration possibilities that specify when each button will appear:

```text
+----------------------------------+---------+------------------------+
|                                  |  Save   |       Save & Grade     |
+----------------------------------+---------+------------------------+
| Manual                           |    ✓    |                        |
| Manual, Internal                 |    ✓    |           ✓            |
| Manual, External                 |    ✓    |           ✓            |
| Manual, Internal, External       |    ✓    |           ✓            |
+----------------------------------+---------+------------------------+
```

The student will only see the "Save" button on a question view that only includes the "Manual" grading method configuration. The "Save & Grade" button appears, in addition, when the "Interal" or "External" option(s) are also included. Each button calls a different back-end function within each element included on the `question.html` page. The "Save" button calls `def parse()` and the "Save & Grade" button calls `def grade()` within an element's python file. For example, if an instructor includes a `pl-string-input` element in a question for manual grading, and a student presses "Save", the `def parse()` method found in the [pl-string-input.py](https://github.com/PrairieLearn/PrairieLearn/blob/master/elements/pl-string-input/pl-string-input.py#L176-L198) element file is called.

## Manual Grading (UI Interactive)

The manual grading view re-uses the student question view, which displays student submissions with their grading results, but adds a manual grading panel to the view. The panel allows a manual grading user to submit a `score` and `feedback`. The score and feedback is added to the latest submission displayed on the manual grading view. The feedback must be a valid string and the score must be a number divisible by 5 and out of 100 percent.

![](manual-grading/grading-panel.png)

To list questions and begin grading, one must have student data viewer privileges and navigate to the course. Click on the assessment to display a list of questions. The navigation bar header will include a "Manual Grading" button.

Clicking on the "Manual Grading" button will navigate to a page that lists all questions with a "Manual" type grading method. This is the "Manual Grading Queue". All questions on an assessment that are configured with the "Manual" grading method will appear in the "Manual Grading Queue".

Each ungraded student submission will count as one ungraded question. Students can save multiple submissions on a question, but only the last ungraded submission is counted. Hence, if a student saves another submission after an item has been manually graded, the "Ungraded" category increments by plus one.

![](manual-grading/list-manual-questions.png)

It is, therefore, recommended that an instructor or TA only submits manual grades after an assessment has closed. If an assessment is left open and a student makes another submission, it would be queued to be manually graded. The choice to leave an assessment open and allow the student to make new submissions after manual grading, ultimately, is up to the discretition of the instructor. The old manual grading score will be overwritten by any further manual grading action on new submissions.

A manual grade is calculated by the instructor and is incompatible with an array of `points` and/or `maxPoints` feature on the question configuration.

### Grade Next

The "Manual Grading Queue" view lists all questions on an assessment that are configured with the "Manual" grading method type. The number of "Ungraded" and "Graded" instance questions are listed beside the question. Each instance question maps to a unique student with the particular student submissions.

The "Grade Next" button appears on questions that have ungraded items. Clicking on the "Grade Next" button will load an ungraded instance question in random order.

### Manual Grading Conflicts

A manual grading conflict occurs when multiple manual grading users click "Grade Next" and land on the same instance question. The first user who lands on the instance question will be oblivious to this scenario. Subsequent users who land on the page will see a warning displayed that reveals the instance question is being graded by the first user.

![](manual-grading/grading-warning.png)

If the first user submits a manual grade and any subsequent user submits a grade, then the subsequent user will be navigated to a new view that displays both manual grading submissions and asks the user to resolve the manual grading conflict. The "Current Grade" is the submission by the second user who did not adhere to the warning displayed on the page. The "Incoming Grade" is the current user's grade who encounters and should resolve the grading conflict.

![](manual-grading/grading-warning.png)

In the scenario that any subsequent user does not resolve the conflict, the instance question will still count as an ungraded instance question in the "Manual Grading Queue". Therefore, the "Grade Next" button will eventually lead a manual grading user to the view to resolve the manual grading conflict.

## Manual Grading Legacy (CSV Upload)

Prairie Learn supports manual grading of questions by downloading a CSV file with student answers and uploading a CSV file with question scores and optional per-question feedback. There is now an online web interface for streamlining manual grading.

Any [elements](elements/) can be used in the [`question.html`](question.md#question-questionhtml) to write manually graded questions. All of the student input will be saved and available for manual grading, including `pl-string-input`, `pl-file-editor`, `pl-file-upload`, etc.

### Downloading Student Answers

After students have completed the assessment, download the submitted answers by going to the assessment page, then the "Downloads" tab, and selecting the `<assessment>_submissions_for_manual_grading.csv` file. This looks like:
```csv
uid,uin,username,name,role,qid,old_score_perc,old_feedback,submission_id,params,true_answer,submitted_answer,old_partial_scores,partial_scores,score_perc,feedback
mwest@illinois.edu,1,,,,explainMax,0,,42983,{},{},{"ans": "returns the maximum value in the array"},,,,
zilles@illinois.edu,2,,,,explainMax,0,,42984,{},{},{"ans": "gives the set of largest values in the object"},,,,
zilles@illinois.edu,2,,,,describeFibonacci,100,,42987,{},{},{"ans": "calculates the n-th Fibonacci number"},,,,
```

This CSV file has three blank columns at the end, ready for the percentage score (0 to 100) and optional feedback and partial scores. The `submission_id` is an internal identifier that PrairieLearn uses to determine exactly which submitted answer is being graded. The `params` and `true_answer` columns show the question data. The `old_score_perc` column shows the score that the student currently has, which is convenient for re-grading or doing optional manual grading after an autograder has already done a first pass. If feedback was already provided in a previous upload, the `old_feedback` column will contain the feedback the student currently has.

If the students uploaded files then you should also download `<assessment>_files_for_manual_grading.zip` from the "Downloads" tab. The scores and feedback should still be entered into the CSV file.

### Uploading Scores and Feedback

After editing the percentage score and/or feedback for each submitted answer, upload the CSV file by going to the assessment page, then the "Uploads" tab, and selecting "Upload new question scores". If you leave either `score_perc` or `feedback` (or both) blank for any student, then the corresponding entry will not be updated.

Each question will have its score and/or feedback updated and the total assessment score will be recalculated. All updates are done with `credit` of 100%, so students get exactly the scores as uploaded.

If you prefer to use points rather than a percentage score, rename the `score_perc` column in the CSV file to `points`.

You also have the option to set partial scores. These can be based on individual elements of the question (typically based on the `answers-name` attribute of the element), or any other setting you wish to use. Partial scores must be represented using a JSON object, with keys corresponding to individual elements. Each element key should be mapped to an object, and should ideally contain values for `score` (with a value between 0 and 1) and `weight` (which defaults to 1 if not present). For example, to assign grades to a question with elements `answer1` and `answer2`, use:

```json
{"answer1": {"score": 0.7, "weight": 2, "feedback": "Almost there!"}, "answer2": {"score": 1, "weight": 1, "feedback": "Great job!"}}
```

If the `partial_scores` column contains a valid value, and there is no value in `score_perc` or `points`, the score will be computed based on the weighted average of the partial scores. For example, the score above will be computed as 80% (the weighted average between 70% with weight 2, and 100% with weight 1).

*WARNING*: note that some elements such as drawings or matrix elements may rely on elaborate partial score values with specific structures and objects. When updating partial scores, make sure you follow the same structure as the original partial scores to avoid any problems. Changing these values could lead to errors on rendering the question pages for these elements.

## Displaying Manual Grading Feedback

To show manual feedback the `question.html` file should contain an element to display the feedback next to student submissions. A basic template for this is:
```html
<pl-submission-panel>
  {{#feedback.manual}}
  <p>Feedback from course staff:</p>
  <markdown>{{{feedback.manual}}}</markdown>
  {{/feedback.manual}}
</pl-submission-panel>
```

This example template formats the feedback as Markdown.

### Workspaces

To include files copied out of the workspace into the `<assessment>_files_for_manual_grading.zip`, in the [`info.json` file](workspaces/index.md#infojson) specify a file list using `"gradedFiles"`

```json
"workspaceOptions": {
        "gradedFiles": [
            "starter_code.h",
            "starter_code.c"
        ],
        ...
}
...
```
