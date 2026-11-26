# GymAssistant

An Android assistant that watches a person train on one of three gym machines through the phone camera, counts repetitions, detects posture errors and gives feedback in real time, then tracks progress over weeks. Headwords are the English names used in code; the Spanish term in parentheses is the one the thesis documents use.

## People and roles

**Anonymous user** (Usuario anónimo):
A person using the app without an account; everything they record exists only on their phone.
_Avoid_: guest, offline user

**Registered user** (Usuario registrado):
A person with an account; can do everything an anonymous user can, plus sync, see the full dashboard and link with a professional.

**Professional** (Profesional):
A registered user whose role request was approved, either as an **instructor** or a **physiotherapist**; both have identical permissions.
_Avoid_: coach, trainer (as role names)

**Linked user** (Usuario vinculado):
A registered user who has an active link with a given professional, from that professional's point of view.
_Avoid_: client, patient, student

**Administrator** (Administrador):
The person who approves role requests and exports research data; during the project this is the researcher.

**Role request** (Solicitud de rol):
A registered user's request to become a professional, which the administrator approves or rejects.

**Link code** (Código de vinculación):
A short-lived, single-use code a professional generates so one user can link with them.

**Link** (Vínculo):
The relationship between a professional and a linked user that lets the professional see that user's progress and assign goals; ending it keeps it as history but removes access.
_Avoid_: connection, subscription

## Training

**Exercise** (Ejercicio):
One of the three supported machines: 45° leg press, lat pulldown, or leg extension. Each has its own camera view and governing joint angle.
_Avoid_: machine (when meaning the analysed movement), workout

**Workout session** (Sesión):
One visit to the gym, containing one or more sets of one or more exercises.
_Avoid_: "session" on its own (collides with a login session), workout, training

**Set** (Serie):
A run of consecutive repetitions of one exercise, closed by recording its weight, RIR and discomfort.
_Avoid_: series

**Repetition** (Repetición):
One complete cycle of the movement through all four phases; it is the unit every technique metric is built from. Each repetition is either correct or carries one or more detected errors.
_Avoid_: rep (in code and docs)

**Partial repetition** (Rango parcial):
A movement that leaves the start position but returns before reaching the turnaround; it is not counted.

**Phase** (Fase):
One stage of a repetition: **START** (rest position), **OUTWARD** (moving away from the start), **TURNAROUND** (the extreme of the range), **RETURN** (moving back to the start). What each phase means physically depends on the exercise.

**Weight** (Peso):
The load in kilograms the user reports for a set.

**RIR** (Repeticiones en reserva):
Repetitions in reserve: how many more repetitions the user believes they could have done when the set ended.

**Discomfort** (Molestia):
An optional 0–10 rating of pain or discomfort the user reports for a set.

## Analysis

**Pose** (Pose):
The 33 body landmarks estimated from a single camera frame.

**Landmark** (Punto articular):
One tracked body point (a hip, knee, ankle, shoulder…) within a pose.
_Avoid_: keypoint, joint (when meaning the tracked point)

**Joint** (Articulación):
A body part named without its side, such as the hip, knee or elbow. Each joint has a left and a right landmark, and the measured side picks which one is analysed.
_Avoid_: landmark (when no side is meant)

**Camera position** (Posición de cámara):
Where the phone stands relative to the user and the machine: **side** (0°, perpendicular to the user's side), **oblique** (diagonal, 30° from the side) or **front**. Each exercise has a recommended camera position: oblique for the leg press, side for the lat pulldown and the leg extension.
_Avoid_: camera angle (collides with joint angles)

**Primary angle** (Ángulo principal):
The joint angle that drives an exercise's phases: the knee for the leg press and the leg extension, the elbow for the lat pulldown.

**Measured side** (Lado medido):
The body side, left or right, whose landmarks an exercise is analysed on. It is chosen when framing becomes valid and stays fixed for the set.

**Framing** (Encuadre):
Whether every landmark an exercise needs is visible to the camera. A set can only start after framing has been valid for a short continuous period.

**Posture rule** (Regla postural):
A detectable error for one exercise, defined by a threshold, a persistence and a priority.

**Detected error** (Error detectado):
An occurrence of a posture rule during a specific repetition.
_Avoid_: mistake, fault, violation

**Torso swing** (Inclinación o balanceo del tronco):
The lat-pulldown error in which the user leans the trunk back to help pull the bar down. It covers both a static lean past about 30° and a change of trunk angle beyond a threshold during the repetition; calibration tunes both limits.
_Avoid_: tilting

**Threshold** (Umbral):
The angle, distance or speed limit at which a posture rule or a phase change fires.

**Persistence** (Persistencia):
The number of consecutive frames a condition must hold before a detected error is confirmed.

**Hysteresis** (Histéresis):
The margin an angle must cross beyond a threshold before the phase changes, so jitter around the threshold doesn't produce false repetitions.

**Priority** (Prioridad):
The rank that decides which alert to show when several errors are detected at once; 1 is the highest.

**Rules version** (Versión de reglas):
The identifier of the set of thresholds a workout session was measured with. Versions 0.x are **provisional** (uncalibrated values for development); 1.0.0 is the first calibrated version.

**Calibration** (Calibración):
Fitting thresholds to labelled recordings from the gym so each posture rule reaches its target accuracy.

**Landmark recording** (Grabación de puntos):
A file with one row per frame for one set: timestamp, the raw landmarks, the primary angle and the context needed to interpret them. It never contains images.
_Avoid_: video, capture, log

**Reference phone** (Teléfono de referencia):
A researcher-owned phone on which calibration recordings, pilot measurements and performance targets are taken, so differences between participants' phones don't affect results.

## Feedback

**Alert** (Alerta):
The on-screen message and sound shown when an error is confirmed; only one is visible at a time.

**Cooldown** (Tiempo mínimo entre mensajes):
The minimum wait before the same alert can be shown again.

**Silent mode** (Modo silencioso):
A way of training in which errors are detected and recorded but no alerts or error summaries are shown; it exists for the research pretest and posttest measurements.
_Avoid_: mute (that only turns off the sound)

**Set summary** (Resumen de la serie):
Shown when a set ends: total repetitions, correct percentage and most frequent error.

**Session summary** (Resumen de la sesión):
Shown when a workout session ends: duration, number of sets, correct percentage and volume per exercise.

## Progress and goals

**Correct percentage** (Porcentaje de repeticiones correctas):
The share of repetitions with no detected error.
_Avoid_: accuracy, score

**Volume** (Volumen):
Weight × repetitions, summed over the sets of one exercise in a period.

**Effective set** (Serie efectiva):
A set finished with RIR ≤ 3.

**Estimated 1RM** (1RM estimada):
The estimated maximum weight for one repetition, computed only from sets of 10 repetitions or fewer.

**Technical decline** (Deterioro técnico):
The drop in correct percentage between the first and last set of the same exercise within one workout session.
_Avoid_: fatigue

**Goal** (Meta):
A measurable target made of an exercise, a metric, a condition (≥ or ≤), a value and a period (week or month). A goal is either **personal** (created and editable by the user) or **assigned** (created by a professional, read-only for the user).
_Avoid_: objective, target

**Goal progress** (Avance de la meta):
How far a goal has been met, from 0 to 100 %. A load goal only counts workout sessions whose correct percentage meets the minimum technique level.

## Data and sync

**Anonymous data** (Datos anónimos):
Workout sessions recorded before the user had an account. When the user registers or logs in for the first time, they can attach this data to the account; otherwise it is deleted.

**Partial dashboard** (Dashboard parcial):
The progress view built only from data stored on the phone; shown offline or to anonymous users.

**Full dashboard** (Dashboard completo):
The progress view built from synced cloud data, with weekly, monthly and per-exercise trends.

**Outbox entry** (Registro de sincronización):
A workout session waiting to be sent to the cloud, together with its delivery state.
_Avoid_: queue item, sync job

**Sync** (Sincronización):
Sending outbox entries to the cloud so each record arrives exactly once, and fetching goals and settings changed elsewhere.
