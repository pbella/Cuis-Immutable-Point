'From Cuis 4.2 of 25 July 2013 [latest update: #2940] on 1 November 2016 at 11:12:47 pm'!

!Number methodsFor: 'converting' stamp: 'pb 11/1/2016 23:11:20'!
@@ y 
	"Primitive. Answer a Point whose x value is the receiver and whose y 
	value is the argument. Optional. No Lookup. See Object documentation 
	whatIsAPrimitive."

	<primitive: 18>
	^Point x: self y: y! !


!Number methodsFor: 'converting' stamp: 'pb 11/1/2016 23:12:09'!
@ y
	"Intercept the instance creation for a zero check"
	^ (self = 0 and: [ y = 0 ])
		ifTrue: [ Point zero ]
		ifFalse: [ self @@ y ].! !

