Cuis-Immutable-Point
==================

Cuis spawns a large number of Point instances every second (anywhere from hundreds to millions, depending on the workload).  Related to this is the fact that Points are effectively immutable (there appear to be no cases where setX:setY: is called after point creation) without actually being immutable.  If they were actually immutable, point creation could be significatly reduced without performance penalties.  Many of the points generated are 0@0 (i.e. #morphTopLeft and the other senders of 0@0 etc.) and many of the operations performed have at least one operand of 0@0 (often making them eligible to be reduced to no-ops)  This work is an attempt to quantify the number of objects created as well as seeing what kinds of improvements could be realized by minimizing the generation of 0@0 Points and the related fan-out without requiring any significant rework of existing Morphic logic.  The main benefit of these changes would be to reduce the number of Point instances created per second and their corresponding GCs which helps stabilize framerates for drawing intensive workloads.  Also, I believe there is work in progress to support immutable objects in the VM which this change could gain further benefit from.

### Files

* README.md - this file
* PointBaseline.pck.st - Trivial metric and benchmark to measure Point allocations before and after the changes (with the exception of the 'aggressive' changes below) 

#### The proposed changes:

* Point-immutable.cs.st - The minimum changes required: Point must be immutable and provide Point zero.
* Point-immutable-optional-optimizations.cs.st - Optional optimizations which eliminate needless work.  This significantly reduces total Point object creation but does not adversely impact performance (which may be slightly faster overall)  Additional higher-level optimizations along these lines should also be possible if these changesets are incorporated into the image.
* Point-zero-senders-1.cs.st - Many of the most commonly called methods with 0@0 instances changed over to Point zero
(these are the 3 changesets I would recommend applying)

#### Additional files:

For completeness, the following exist to try to intercept as many of the remaining zero point instance creations as possible.  Doing it this way was fast to implement but does have an adverse performance impact so incorporating into the base image is not recommended.  Some fraction of these would be captured by changing the remaining 100 0@0 sends in the base image:

* Point-immutable-aggressive-optimizations.cs.st
* PointBaselineAggressive.pck.st

Quantify Point creation in a couple of easily reproducible scenarios:

* Trivial benchmarks.ods - some stats produced by calling 'PointBaseline getCounts' under different conditions
* Desktop layout for benchmark.png - the window layout used for the benchmarks if you want to try to replicate my measurements
