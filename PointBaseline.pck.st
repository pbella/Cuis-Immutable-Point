'From Cuis 4.2 of 25 July 2013 [latest update: #2940] on 1 November 2016 at 7:31:15 pm'!
'Description This provides a baseline look at point creation in the image as-is.  *NOT* part of the proposed changesets.'!
!provides: 'PointBaseline' 1 0!
!requires: 'BouncingAtoms' 1 29 nil!
!classDefinition: #Point category: #'Graphics-Primitives'!
Object subclass: #Point
       instanceVariableNames: 'x y '
       classVariableNames: 'Zero ICreated'
       poolDictionaries: ''
       category: 'Graphics-Primitives'!

!classDefinition: #PointBaseline category: #PointBaseline!
Object subclass: #PointBaseline
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'PointBaseline'!
!classDefinition: 'PointBaseline class' category: #PointBaseline!
PointBaseline class
	instanceVariableNames: ''!


!Point class methodsFor: '*PointBaseline' stamp: 'pb 11/1/2016 19:24:24'!
counter
	^ ICreated.! !

!Point class methodsFor: '*PointBaseline' stamp: 'pb 11/1/2016 19:24:20'!
resetCounter
	ICreated _ 0.! !

Point resetCounter!

!Point class methodsFor: '*PointBaseline' stamp: 'pb 11/1/2016 19:24:16'!
x: anX y: anY
	ICreated _ ICreated + 1.
	^ self new
		
			instVarNamed: 'x'
			put: anX;
		
			instVarNamed: 'y'
			put: anY;
		yourself.! !

!PointBaseline class methodsFor: 'as yet unclassified' stamp: 'pb 11/1/2016 19:31:12'!
getCounts
	[ | incrGc fullGc stats |
	stats := Dictionary new.
	Smalltalk garbageCollect.
	incrGc := Smalltalk getVMParameters at: 9.
	fullGc := Smalltalk getVMParameters at: 7.
	Point resetCounter.
	(Delay forSeconds: 60) wait.
	stats at: 'idle count' put: Point counter;
		at: 'idle incr gc' put: ((Smalltalk getVMParameters at: 9) - incrGc);
		at: 'idle full gc' put: ((Smalltalk getVMParameters at: 7) - fullGc).
	BouncingAtomsMorph initializedInstance openInWorld.
	Smalltalk garbageCollect.
	incrGc := Smalltalk getVMParameters at: 9.
	fullGc := Smalltalk getVMParameters at: 7.
	Point resetCounter.
	(Delay forSeconds: 60) wait.
	stats at: 'active count' put: Point counter;
		at: 'active incr gc' put: ((Smalltalk getVMParameters at: 9) - incrGc);
		at: 'active full gc' put: ((Smalltalk getVMParameters at: 7) - fullGc).
	Workspace new contents: stats asString;
		 openLabel: 'Results'] newProcess resume.! !

!Number methodsFor: '*PointBaseline' stamp: 'pb 11/1/2016 19:24:32'!
@ y 
	"Primitive. Answer a Point whose x value is the receiver and whose y 
	value is the argument. Optional. No Lookup. See Object documentation 
	whatIsAPrimitive."

	^Point x: self y: y! !

!Number methodsFor: '*PointBaseline' stamp: 'pb 11/1/2016 19:24:27'!
adaptToPoint: rcvr andSend: selector
	"If I am involved in arithmetic with a Point, convert me to a Point."
	^ rcvr perform: selector with: (Point x: self y: self)! !

