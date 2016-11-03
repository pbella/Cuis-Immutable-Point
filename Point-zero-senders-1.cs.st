'From Cuis 4.2 of 25 July 2013 [latest update: #2960] on 30 October 2016 at 9:44:19 pm'!

!Form methodsFor: 'filling' stamp: 'pb 10/30/2016 21:42:40'!
fill: aRectangle rule: anInteger fillColor: aForm 
	"Replace a rectangular area of the receiver with the pattern described by aForm 
	according to the rule anInteger."
	(BitBlt toForm: self)
		copy: aRectangle
		from: Point zero in: nil
		fillColor: aForm rule: anInteger! !


!SystemWindow methodsFor: 'drawing' stamp: 'pb 10/30/2016 21:43:09'!
drawRoundedFrameOn: aCanvas color: widgetsColor
	"Title area is not inside window borders"
	| bottomFactor topFactor |
	Theme current useWindowTitleGradient
		ifTrue: [
			topFactor _ Theme current titleGradientTopFactor.
			bottomFactor _ Theme current titleGradientBottomFactor ]
		ifFalse: [
			topFactor _ 1.
			bottomFactor _ 1 ].
	aCanvas
		windowFrame: (Point zero extent: extent)
		color: widgetsColor * Theme current titleGradientExtraLightness
		radius: Theme current roundedWindowRadius
		border: borderWidth
		labelHeight: self labelHeight + borderWidth
		gradientTop: topFactor
		gradientBottom: bottomFactor
		insideColor: color! !


!InnerTextMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 21:43:27'!
drawOn: aCanvas
	"Draw the receiver on a canvas"

	false ifTrue: [ self debugDrawLineRectsOn: aCanvas ].  "show line rects for debugging"

	aCanvas
		textComposition: self textComposition
		bounds: (Point zero extent: extent)
		color: color
		selectionColor: (Theme current textHighlightFocused: self hasKeyboardFocus)! !


!MorphicCanvas methodsFor: 'drawing-text' stamp: 'pb 10/30/2016 21:43:57'!
textComposition: aTextComposition bounds: boundsRect color: c selectionColor: sc
	| displayScanner leftInRun line boundsInWorld tl |

	tl _ boundsRect topLeft.
	boundsInWorld _ currentTransformation displayBoundsOfTransformOf: boundsRect.

	displayScanner _ MorphicScanner new
		defaultFont: aTextComposition defaultFont;
		text: aTextComposition textComposed
		foreground: c.
	displayScanner canvas: self.

	leftInRun _ 0.
	"Take clipRect into account. Extrememly fast scrolls and redraws of huge files (like .sources)"
	(aTextComposition lineIndexForPoint: (Point zero max: (clipLeft@clipTop)- boundsInWorld origin))
		to: (aTextComposition lineIndexForPoint: (boundsInWorld extent min: (clipRight@clipBottom+1) - boundsInWorld origin))
		do: [ :i |
			line _ aTextComposition lines at: i.
			aTextComposition
				displaySelectionInLine: line
				on: self
				textTopLeft: tl
				selectionColor: sc.
			leftInRun _ displayScanner displayLine: line textTopLeft: tl leftInRun: leftInRun  ]! !

!InputSensor methodsFor: 'private' stamp: 'pb 10/30/2016 22:28:42'!
primMousePt
	"Primitive. Poll the mouse to find out its position. Return a Point. Fail if
	event-driven tracking is used instead of polling. Optional. See Object
	documentation whatIsAPrimitive."

	<primitive: 90>
	^ Point zero! !


!String methodsFor: 'displaying' stamp: 'pb 10/30/2016 22:23:16'!
displayOn: aDisplayMedium
	"Display the receiver on the given DisplayMedium.  5/16/96 sw"

	self displayOn: aDisplayMedium at: Point zero! !


!Bitmap methodsFor: 'as yet unclassified' stamp: 'pb 10/30/2016 22:26:19'!
asByteArray
	"Faster way to make a byte array from me.
	copyFromByteArray:, if receiver is BigEndian makes equal Bitmap.
	Assume receiver bytes-in-word mapping is BigEndian:
		Most significant bye of first word in self goes to first position in result.
	This means that for a BigEndian 8bpp Form, pixels are in the right order in the ByteArray
	
	Form lena asGrayForm bits asByteArray copyFrom: 1 to: 4.
	(Form lena asGrayForm asFormOfDepth: 8) bits asByteArray copyFrom: 1 to: 4.
	(0 to: 3) collect: [ :x | ((Form lena asGrayForm colorAt: x@0) luminance * 255) rounded ].
	"
	| f bytes hack |
	f _ Form extent: 4@self size depth: 8 bits: self.
	bytes _ ByteArray new: self size * 4.
	hack _ Form new hackBits: bytes.
	Smalltalk isLittleEndian ifTrue: [hack swapEndianness].
	hack copyBits: f boundingBox
		from: f
		at: (Point zero)
		clippingBox: hack boundingBox
		rule: Form over.

	"f displayOn: hack."
	^ bytes! !


!RealEstateAgent class methodsFor: 'as yet unclassified' stamp: 'pb 10/30/2016 22:23:41'!
strictlyStaggeredInitialFrameFor: aStandardSystemView initialExtent: initialExtent world: aWorld 
	"This method implements a staggered window placement policy that I (di) like.
	Basically it provides for up to 4 windows, staggered from each of the 4 corners.
	The windows are staggered so that there will always be a corner visible."

	| allowedArea grid initialFrame otherFrames cornerSel corner delta putativeCorner free maxLevel |
	allowedArea := (self maximumUsableAreaInWorld: aWorld) 
				insetBy: (self scrollBarSetback @ self screenTopSetback extent: Point zero).
	"Number to be staggered at each corner (less on small screens)"
	maxLevel := allowedArea area > 300000 ifTrue: [3] ifFalse: [2].
	"Amount by which to stagger (less on small screens)"
	grid := allowedArea area > 500000 ifTrue: [40] ifFalse: [20].
	initialFrame := Point zero extent: initialExtent.
	"min: (allowedArea extent - (grid*(maxLevel+1*2) + (grid//2))))
							min: 600@400"
	otherFrames := (SystemWindow windowsIn: aWorld satisfying: [ :w | w visible and: [w isCollapsed not]]) 
						collect: [:w | w morphBoundsInWorld].
	otherFrames _ otherFrames reject: [ :f | f isNil ].
	0 to: maxLevel do: [ :level | 
			1 to: 4 do: [:ci | 
					cornerSel := #(#topLeft #topRight #bottomRight #bottomLeft) at: ci.
					corner := allowedArea perform: cornerSel.
					"The extra grid//2 in delta helps to keep title tabs distinct"
					delta := ((maxLevel - level) * grid + (grid // 2)) @ (level * grid).
					1 to: ci - 1 do: [ :i | delta _ delta y negated @ delta x ].	"slow way"
					putativeCorner := corner + delta.
					free := true.
					otherFrames do: [ :w |
						free := free & ((w perform: cornerSel) ~= putativeCorner)].
					free 
						ifTrue: [
							^(initialFrame aligned: (initialFrame perform: cornerSel)
								with: putativeCorner) translatedAndSquishedToBeWithin: allowedArea]]].
	"If all else fails..."
	^(self scrollBarSetback @ self screenTopSetback 
		extent: initialFrame extent) translatedAndSquishedToBeWithin: allowedArea! !


!Form methodsFor: 'coloring' stamp: 'pb 10/30/2016 22:27:10'!
fillShape: aShapeForm fillColor: aColor
	"Fill a region corresponding to 1 bits in aShapeForm with aColor"

	^ self fillShape: aShapeForm fillColor: aColor at: Point zero! !

!Form methodsFor: 'coloring' stamp: 'pb 10/30/2016 22:27:17'!
fillShape: aShapeForm fillColor: aColor at: location
	"Fill a region corresponding to 1 bits in aShapeForm with aColor"

	((BitBlt destForm: self sourceForm: aShapeForm fillColor: aColor
		combinationRule: Form paint
		destOrigin: location + aShapeForm offset sourceOrigin: Point zero
		extent: self extent clipRect: self boundingBox)
		colorMap: (Bitmap with: 0 with: 16rFFFFFFFF))
		copyBits! !

!Form methodsFor: 'display box access' stamp: 'pb 10/30/2016 22:22:09'!
boundingBox
	^ Rectangle origin: Point zero
			corner: width @ height! !

!Form methodsFor: 'displaying-generic' stamp: 'pb 10/30/2016 22:22:20'!
displayOn: aDisplayMedium
	"Simple default display in order to see the receiver in the upper left 
	corner of screen."

	self displayOn: aDisplayMedium at: Point zero! !

!Form methodsFor: 'private' stamp: 'pb 10/30/2016 22:22:14'!
copyFromByteArray: bigEndianByteArray
	"This method should work with either byte orderings.
	See comment at Bitmap>>#asByteArray
	Also see #copyFromByteArray2:to:"

	| myHack byteHack |
	myHack := Form new hackBits: bits.
	byteHack := Form new hackBits: bigEndianByteArray.
	"We are passing a ByteArray instead of a Words object. Will be accessed according to native endianness."
	Smalltalk isLittleEndian = self isLittleEndian ifFalse: [byteHack swapEndianness].
	byteHack displayOn: myHack at: Point zero rule: Form over! !

!Form methodsFor: 'initialization' stamp: 'pb 10/30/2016 22:22:26'!
fromDisplay: aRectangle 
	"Create a virtual bit map from a user specified rectangular area on the 
	display screen. Reallocates bitmap only if aRectangle ~= the receiver's 
	extent."

	(width = aRectangle width and: [height = aRectangle height])
		ifFalse: [self setExtent: aRectangle extent depth: depth].
	self
		copyBits: (aRectangle origin extent: self extent)
		from: Display
		at: Point zero
		clippingBox: self boundingBox
		rule: Form over! !


!Cursor class methodsFor: 'instance creation' stamp: 'pb 10/30/2016 22:21:54'!
new

	^ self extent: 16 @ 16
		fromArray: (Array new: 16 withAll: 0)
		offset: Point zero

	"Cursor new bitEdit show"! !


!AffineTransformation methodsFor: 'converting coordinates' stamp: 'pb 10/30/2016 22:25:18'!
internalizeDelta: aPoint
	"Internalize a distance vector. A distance is not a position. It is a magnitude with a direction.
	It is usually used as a delta to be added to a position to obtain some other position."

	| x y det a11 a12 a21 a22 detX detY |
	x _ aPoint x.
	y _ aPoint y.
	a11 _ self a11.
	a12 _ self a12.
	a21 _ self a21.
	a22 _ self a22.
	det _ (a11 * a22) - (a12 * a21).
	det = 0.0 ifTrue: [ ^Point zero ].		"So we have at least a valid result"
	det _ 1.0 / det.
	detX _ (x * a22) - (a12 * y).
	detY _ (a11 * y) - (x * a21).
	^(detX * det) @ (detY * det)! !

!AffineTransformation methodsFor: 'converting coordinates' stamp: 'pb 10/30/2016 22:25:25'!
inverseTransform: aPoint
	"Apply the inverse transformation to aPoint, i.e. multiply our inverse by aPoint.
	Use Smalltalk code, and not Matrix2x3Plugin, because we want Float conversion."
	| x y det a11 a12 a21 a22 detX detY |

	x _ aPoint x - self a13.
	y _ aPoint y - self a23.
	a11 _ self a11.
	a12 _ self a12.
	a21 _ self a21.
	a22 _ self a22.
	det _ (a11 * a22) - (a12 * a21).
	det = 0.0 ifTrue: [ ^Point zero ].		"So we have at least a valid result"
	det _ 1.0 / det.
	detX _ (x * a22) - (a12 * y).
	detY _ (a11 * y) - (x * a21).
	^(detX * det) @ (detY * det)! !

!AffineTransformation methodsFor: 'accessing' stamp: 'pb 10/30/2016 22:25:33'!
inverseTransformation
	"Return the inverse transformation of the receiver.
	The inverse transformation is computed by first calculating
	the inverse offset and then computing transformations
	for the two identity vectors (1@0) and (0@1)"
	| r1 r2 r3 m |
	r3 _ self inverseTransform: Point zero.
	r1 _ (self inverseTransform: 1@0) - r3.
	r2 _ (self inverseTransform: 0@1) - r3.
	m _ self species new.
	m
		a11: r1 x; a12: r2 x; a13: r3 x;
		a21: r1 y; a22: r2 y; a23: r3 y.
	^m! !

!AffineTransformation methodsFor: 'transforming rects' stamp: 'pb 10/30/2016 22:24:52'!
displayBoundsOfTransformOf: aRectangle
	"Externalize aRectangle, and find a bounding rectangle with horizontal 
		and vertical bounds and integer coordinates (i.e. adisplayBounds).
	Primitive rounds and answers integers.
	Warning: if answer from primitive is not strictly positive, it is off by one. Fix it here."

	| dstRect |
	dstRect _ Rectangle new.
	(self primDisplayBoundsOfTransformOf: aRectangle into: dstRect) ifNotNil: [
		dstRect topLeft > (Point zero) ifTrue: [ ^dstRect  ]].
	^Rectangle encompassing: (aRectangle corners collect: [ :pt |
		(self transform: pt) rounded ])! !


!Rectangle class methodsFor: 'instance creation' stamp: 'pb 10/30/2016 22:34:28'!
fromUser
	"Answer a Rectangle that is determined by having the user 
	designate the top left and bottom right corners."
	| originRect |
	originRect _ Cursor origin showWhile: 
		[(Sensor mousePoint extent: Point zero) newRectFrom:
			[:f | Sensor mousePoint  extent: Point zero]].
	^ Cursor corner showWhile:
		[originRect newRectFrom:
			[:f | f origin corner: Sensor mousePoint ]]! !


!StrikeFont methodsFor: 'emphasis' stamp: 'pb 10/30/2016 22:35:26'!
makeItalicGlyphs
	"Make an italic set of glyphs with same widths by skewing left and right.
	In the process, characters would overlap, so we widen them all first.
	"
	| extraWidth newGlyphs newXTable x newX w extraOnLeft |  
	extraOnLeft _ (self height-1-self ascent+4)//4 max: 0.
	extraWidth _ ((self ascent-5+4)//4 max: 0) + extraOnLeft.
	newGlyphs _ Form extent: (glyphs width + (maxAscii + 1 - minAscii*extraWidth)) @ glyphs height depth: glyphs depth.
	newGlyphs fillWhite.
	newXTable _ xTable copy.

	"Copy glyphs into newGlyphs with room on left and right for overlap."
	minAscii to: maxAscii+1 do:
		[:ascii | x _ xTable at: ascii+1.  w _ (xTable at: ascii+2) - x.
		newX _ newXTable at: ascii+1.
		newGlyphs copy: ((newX + extraOnLeft) @ 0 extent: w @ glyphs height)
			from: x @ 0 in: glyphs rule: Form over.
		newXTable at: ascii+2 put: newX + w + extraWidth].		
	glyphs _ newGlyphs. 
	xTable _ newXTable.
	"Slide the bitmaps left and right for synthetic italic effect."
	4 to: self ascent-1 by: 4 do:
		[:y | 		"Slide ascenders right..."
		glyphs copy: (1@0 extent: glyphs width @ (self ascent - y))
			from: Point zero in: glyphs rule: Form over].
	self ascent to: self height-1 by: 4 do:
		[:y | 		"Slide descenders left..."
		glyphs copy: (0@y extent: glyphs width @ glyphs height)
			from: 1@y in: glyphs rule: Form over].
	self isSynthetic: true! !

!StrikeFont methodsFor: 'glyphs' stamp: 'pb 10/30/2016 22:35:16'!
glyphAt: character put: characterForm
	"Copy characterForm over the glyph for the argument, character."
	| ascii leftX rightX widthDif newGlyphs |
	ascii _ character numericValue.
	ascii < minAscii ifTrue: [^ self error: 'Cant store characters below min ascii'].
	ascii > maxAscii ifTrue:
		[(self confirm:
'This font does not accomodate ascii values higher than ' , maxAscii printString , '.
Do you wish to extend it permanently to handle values up to ' , ascii printString)
			ifTrue: [self extendMaxAsciiTo: ascii]
			ifFalse: [^ self error: 'No change made']].
	leftX _ xTable at: ascii + 1.
	rightX _ xTable at: ascii + 2.
	widthDif _ characterForm width - (rightX - leftX).
	widthDif ~= 0 ifTrue:
		["Make new glyphs with more or less space for this char"
		newGlyphs _ Form extent: (glyphs width + widthDif) @ glyphs height depth: glyphs depth.
		newGlyphs copy: (Point zero corner: leftX@glyphs height)
			from: Point zero in: glyphs rule: Form over.
		newGlyphs copy: ((rightX+widthDif)@0 corner: newGlyphs width@glyphs height)
			from: rightX@0 in: glyphs rule: Form over.
		glyphs _ newGlyphs.
		"adjust further entries on xTable"
		xTable _ xTable copy.
		ascii+2 to: xTable size
			do: [:i | xTable at: i put: (xTable at: i) + widthDif]].
	glyphs copy: (leftX @ 0 extent: characterForm extent)
		from: Point zero in: characterForm rule: Form over
"
| f |  f _ AbstractFont default.
f glyphAt: $  put: (Form extent: (f widthOf: $ )+10@f height)
"! !

!StrikeFont methodsFor: 'building' stamp: 'pb 10/30/2016 22:34:49'!
buildFromForm: allGlyphs data: data name: aString

	| x shortUnderscore |
	pointSize _ data first asNumber.
	ascent _ data second asNumber.
	descent _ data third asNumber.
	
	minAscii _ 28.
	maxAscii _ 255.
	name _ aString.
	type _ 0.  "ignored for now"
	superscript _ ascent - descent // 3.	
	subscript _ descent - ascent // 3.	
	emphasis _ 0.

	xTable _ (Array new: 258) atAllPut: 0.
	maxWidth _ 0.
	glyphs _ allGlyphs depth > 16 ifTrue: [ allGlyphs asFormOfDepth: 16 ] ifFalse: [ allGlyphs ].
	x _ 0.
	minAscii to: maxAscii+1 do: [ :i |
		x _ (data at: i-minAscii+4) asNumber.
		xTable at: i+1 put: x].
	xTable at: 258 put: x.
	self reset.
	derivativeFonts _ nil.
	
	"Replace glyph for 127 (a box) with a short version of the underscore (used to optionally mark subscript in code)"
	shortUnderscore _ self glyphAt: $_.
	shortUnderscore _ shortUnderscore copy: (Point zero extent: 1@shortUnderscore height).
	self glyphAt: (Character numericValue: 127) put: shortUnderscore! !

!StrikeFont methodsFor: 'building' stamp: 'pb 10/30/2016 22:35:36'!
stripHighGlyphs
	"Remove glyphs for characters above 128"
	| i |

	characterToGlyphMap _ nil.
	maxAscii _ 127.
	
	xTable _ xTable copyFrom: 1 to: maxAscii + 3.
	i _ xTable at: maxAscii + 2.
	xTable at: maxAscii + 3 put: i.
	glyphs _ glyphs copy: (Point zero extent: i+1@glyphs height).
	maxWidth _ 0.
	2 to: xTable size do: [ :ii |
		maxWidth _ maxWidth max: (xTable at: ii) - (xTable at: ii-1)-1 ].
	self reset! !


!Morph methodsFor: 'events-processing' stamp: 'pb 10/30/2016 22:31:09'!
processUnknownEvent: aMorphicEvent localPosition: localEventPosition
	"An event of an unknown type was sent to the receiver. What shall we do?!!"

	Smalltalk beep. 
	aMorphicEvent printString displayAt: Point zero.
	aMorphicEvent wasHandled: true! !

!Morph methodsFor: 'geometry' stamp: 'pb 10/30/2016 22:30:55'!
morphPositionInWorld

	self flag: #jmvVer2.
	"Most likely we don't want to use global coordinates...
	In fact, we could be in many frames of reference at the same time...
	This method makes no sense at all!!"

	^self externalizeToWorld: Point zero! !

!Morph methodsFor: 'geometry' stamp: 'pb 10/30/2016 22:31:01'!
morphTopLeft
	"By default, morphs occupy a rectangle specified by #morphTopLef and #morphExtent"
	^Point zero! !


!PasteUpMorph methodsFor: 'change reporting' stamp: 'pb 10/30/2016 22:32:44'!
invalidateDisplayRect: damageRect from: aMorph
        "Clip damage reports to my bounds, since drawing is clipped to my bounds."

        self == self world 
                ifTrue: [ worldState recordDamagedRect: (damageRect intersect: ( Point zero extent: extent) ) ]
                ifFalse: [ super invalidateDisplayRect: damageRect from: aMorph ]
! !

!PasteUpMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:32:08'!
drawOn: aCanvas

	"draw background image."
	backgroundImage
		ifNotNil: [
			aCanvas image: backgroundImage at: Point zero ]
		ifNil: [
			"draw background fill"
			(self isWorldMorph and: [ aCanvas drawsOnDisplay ] and: [ color class == TranslucentColor ])
				ifTrue: [
					"Special case so a translucent background on the Display allows you to see through the main Cuis Window.
					Requires proper handling of translucent Display in the VM.
					Seems to work only on Linux when using a composing window manager."
					(BitBlt toForm: Display) clipRect: aCanvas clipRect;
						copy: Display boundingBox
						from: Point zero in: nil
						fillColor: color rule: Form over.
					Display forceToScreen]
				ifFalse: [ super drawOn: aCanvas ]]! !

!PasteUpMorph methodsFor: 'geometry' stamp: 'pb 10/30/2016 22:32:52'!
morphPositionInWorld

	self flag: #jmvVer2. "Solo para evitar los warning por falta de owner... pensar despues este caso"
	self isWorldMorph ifTrue: [ ^ Point zero ].
	^super morphPositionInWorld! !

!PasteUpMorph methodsFor: 'world state' stamp: 'pb 10/30/2016 22:32:20'!
fillRects: rectangleList color: aColor
	"For testing. Flashes the given list of rectangles on the Display so you can watch incremental redisplay at work."


	| blt screenRect |
	blt _ (BitBlt toForm: Display)
		sourceForm: nil;
		sourceOrigin: Point zero;
		clipRect: self viewBox;
		fillColor: aColor;
		combinationRule: Form over.

	rectangleList do: [:r |
		screenRect _ r translatedBy: self viewBox origin.
		blt destRect: screenRect; copyBits.
		Display forceToScreen: screenRect ].

	(Delay forMilliseconds: 150) wait! !

!PasteUpMorph methodsFor: 'world state' stamp: 'pb 10/30/2016 22:32:29'!
flashRects: rectangleList color: aColor
	"For testing. Flashes the given list of rectangles on the Display so you can watch incremental redisplay at work."
	"Details: Uses two reverses so that the display is restored to its original state. This is necessary when in deferred update mode."

	| blt screenRect |
	blt _ (BitBlt toForm: Display)
		sourceForm: nil;
		sourceOrigin: Point zero;
		clipRect: self viewBox;
		fillColor: aColor;
		combinationRule: Form reverse.

	rectangleList do: [:r |
		screenRect _ r translatedBy: self viewBox origin.
		blt destRect: screenRect; copyBits.
		Display forceToScreen: screenRect ].

	(Delay forMilliseconds: 250) wait.

	rectangleList do: [:r |
		screenRect _ r translatedBy: self viewBox origin.
		blt destRect: screenRect; copyBits.
		Display forceToScreen: screenRect ]! !


!EllipseMorph methodsFor: 'geometry testing' stamp: 'pb 10/30/2016 22:26:52'!
morphContainsPoint: aLocalPoint

	| radius other delta xOverY |
	((Point zero extent: extent) containsPoint: aLocalPoint) ifFalse: [^ false].  "quick elimination"
	extent > (1@1)
		ifFalse: [^ true].  "Degenerate case -- code below fails by a bit"

	radius _ extent y asFloat / 2.
	other _ extent x asFloat / 2.
	delta _ aLocalPoint - (other@radius).
	xOverY _ extent x asFloat / extent y asFloat.
	^ (delta x asFloat / xOverY) squared + delta y squared <= radius squared! !


!PluggableButtonMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:33:01'!
draw3DLookOn: aCanvas

	| borderStyleSymbol c |
	borderStyleSymbol _ self isPressed ifFalse: [ #raised ] ifTrue: [ #inset ].
	c _ color.
	self mouseIsOver ifTrue: [ c _ c  lighter ].
	aCanvas
		fillRectangle: (Point zero extent: extent)
		color: c
		borderWidth: borderWidth
		borderStyleSymbol: borderStyleSymbol
		baseColorForBorder: c.

	self drawRegularLabelOn: aCanvas! !

!PluggableButtonMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:33:14'!
drawRoundGradientLookOn: aCanvas
	| r colorForButton rect bottomFactor topFactor |

	self isPressed
		ifFalse: [
			topFactor _ Theme current buttonGradientTopFactor.
			bottomFactor _ Theme current buttonGradientBottomFactor.
			self mouseIsOver
				ifTrue: [	
					colorForButton _ Color h: color hue s: color saturation * 1.3 v: color brightness * 0.9 ]
				ifFalse: [
					colorForButton _ color ]]
		ifTrue: [
			topFactor _ Theme current buttonGradientBottomFactor.
			bottomFactor _ Theme current buttonGradientTopFactor.
			colorForButton _ color adjustSaturation: 0.1 brightness: -0.1 ].

	colorForButton ifNotNil: [
		r _ Theme current roundedButtonRadius.
		Theme current useButtonGradient
			ifTrue: [
				rect _ (Point zero extent: extent) insetBy: 1@3.
				aCanvas
					roundRect: rect
					color: colorForButton
					radius: r
					gradientTop: topFactor
					gradientBottom: bottomFactor
					gradientHeight: Theme current buttonGradientHeight ]
			ifFalse: [
				rect _ (Point zero extent: extent) insetBy: 1@3.
				aCanvas roundRect: rect color: colorForButton radius: r ]
		].

	Theme current embossedButtonLabels
		ifTrue: [ self drawEmbossedLabelOn: aCanvas ]
		ifFalse: [ self drawRegularLabelOn: aCanvas ]! !

!PluggableButtonMorph methodsFor: 'geometry testing' stamp: 'pb 10/30/2016 22:33:24'!
morphContainsPoint: aLocalPoint

	| iconOrigin |
	((Point zero extent: extent) containsPoint: aLocalPoint) ifFalse: [ ^false ].
	^ self isOrthoRectangularMorph or: [
		magnifiedIcon isNil or: [
			iconOrigin _ extent - magnifiedIcon extent // 2.
			(magnifiedIcon isTransparentAt: (aLocalPoint - iconOrigin) rounded) not ]]! !


!PluggableScrollPane methodsFor: 'access' stamp: 'pb 10/30/2016 22:33:50'!
addToScroller: aMorph

	scroller
		addMorph: aMorph position: Point zero;
		morphExtent: aMorph morphExtent! !

!PluggableScrollPane methodsFor: 'initialization' stamp: 'pb 10/30/2016 22:24:28'!
initialize
	
	"initialize the state of the receiver"
	super initialize.
	hideScrollBars _ false.

	"initialize the receiver's scrollBars"
	scrollBar _ self scrollBarClass new model: self setValueSelector: #vScrollBarValue:.
	hScrollBar _ self scrollBarClass new model: self setValueSelector: #hScrollBarValue:.
	drawKeyboardFocusIndicator _ true.

	scroller _ self innerMorphClass new.
	self addMorph: scroller.
	self scrollerOffset: Point zero.
	self addMorph: scrollBar.
	self addMorph: hScrollBar.! !

!PluggableScrollPane methodsFor: 'scrolling' stamp: 'pb 10/30/2016 22:33:57'!
scrollToShow: aRectangle
	"scroll to include as much of aRectangle as possible, where aRectangle is in the scroller's local space.
	This means that 0@0 is scrolling all the way top and all the way left"
	| delta |
	(aRectangle top >= 0 and: [
		aRectangle bottom <= self viewableHeight ])
		ifTrue: [
			"already visible"
			^self ].

	"Scroll end of selection into view if necessary"
	delta _ aRectangle amountToTranslateWithin: (Point zero extent: self viewableExtent).
	delta y ~= 0 ifTrue: [
		self scrollBy: 0@delta y ]! !


!PluggableListMorphOfMany methodsFor: 'events' stamp: 'pb 10/30/2016 22:33:37'!
mouseMove: aMouseMoveEvent localPosition: localEventPosition
	"The mouse has moved, as characterized by the event provided.  Adjust the scrollbar, and alter the selection as appropriate"

	| oldIndex oldVal row |
	row _ (localEventPosition y < 0 and: [ scrollBar value > 0.0 ])
		ifTrue: [
			scrollBar scrollUp: 1.
			"Leave at least one visible item unaffected, for better visual feedback to the user."
			(self rowAtLocation: Point zero) + 2 ]
		ifFalse: [
			(localEventPosition y > extent y and: [ scrollBar value < 1.0 ])
				ifTrue: [
					scrollBar scrollDown: 1.
					"Leave at least one visible item unaffected, for better visual feedback to the user."
					(self rowAtLocation: 0@extent y) - 3 ]
				ifFalse: [ self rowAtLocation: localEventPosition ]].
	row = 0 ifTrue: [ ^ self ].

	"No change if model is locked"
	self owningWindow ifNotNil: [ :w |
		w okToChange ifFalse: [^ self]].

	dragOnOrOff ifNil: [
		"Was not set at mouse down, which means the mouse must have gone down in an area where there was no list item"
		dragOnOrOff _ (self listSelectionAt: row) not.
		dragStartRow _ row ].

	"Set meaning for subsequent dragging of selection"
	oldIndex _ self getCurrentSelectionIndex.
	oldIndex ~= 0 ifTrue: [ oldVal _ self listSelectionAt: oldIndex ].

	"Set or clear new primary selection (listIndex)"
	dragOnOrOff 
		ifTrue: [ self changeModelSelection: row ]
		ifFalse: [ self changeModelSelection: 0 ].

	"Need to restore the old one, due to how model works, and set new one."
	oldIndex ~= 0 ifTrue: [ self listSelectionAt: oldIndex put: oldVal ].
	
	"Select all in between if drag was too fast"
	"self listSelectionAt: row put: dragOnOrOff."
	(row min: dragStartRow) to: (row max: dragStartRow) do: [ :r |
		self listSelectionAt: r put: dragOnOrOff ]! !


!SystemWindow methodsFor: 'change reporting' stamp: 'pb 10/30/2016 22:36:20'!
invalidateTitleArea

	"not really pretty... also invalidating the top border, regardless of it being above or below the title area
	(Different themes use various looks, this covers them all)"
	self invalidateLocalRect: (Point zero extent: extent x @ (self labelHeight + borderWidth))! !

!SystemWindow methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:36:13'!
drawClassicFrameOn: aCanvas color: titleColor
	"Window border encompasses title area. No round corners. No title gradient."

	aCanvas fillRectangle: (Point zero extent: extent) color: color borderWidth: borderWidth borderStyleSymbol: #simple baseColorForBorder: self widgetsColor.

	"A border was drawn at the left, top and right of the title area.
	The look is that the title area is inside the window"
	aCanvas fillRectangle: (borderWidth@borderWidth extent: extent x - (2*borderWidth)@ self labelHeight) color: titleColor! !

!SystemWindow methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:36:49'!
makeMeFullyVisible 

	self world morphExtent > (Point zero) ifFalse: [^ self].

	(self morphPosition >= (Point zero) and: [ self morphPosition < (self world morphExtent-self morphExtent)]) ifTrue: [
		^ self "OK -- visible"].

	self morphPosition: (RealEstateAgent initialFrameFor: self initialExtent: self morphExtentInWorld world: self world) topLeft! !

!SystemWindow methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:37:06'!
makeMeVisible 

	self world morphExtent > (Point zero) ifFalse: [^ self].

	(self morphPosition >= (Point zero) and: [ self morphPosition < (self world morphExtent-self labelHeight)]) ifTrue: [
		^ self "OK -- at least my top left is visible"].

	"window not on screen (probably due to reframe) -- move it now"
	self morphPosition: (RealEstateAgent initialFrameFor: self initialExtent: extent world: self world) topLeft! !

!SystemWindow methodsFor: 'initialization' stamp: 'pb 10/30/2016 22:36:04'!
boxExtent
	"answer the extent to use in all the buttons. 
	 
	the label height is used to be proportional to the fonts preferences"
	| e |
	Theme current minimalWindows ifTrue: [^Point zero].
	e _ Preferences windowTitleFont height.
	^e@e! !

!SystemWindow methodsFor: 'layout' stamp: 'pb 10/30/2016 22:36:26'!
layoutSubmorphs
	"Compute a new layout of submorphs based on the given layout bounds."

	| h thickness w cornerExtent wh ww pos |
	thickness _ 4.
	cornerExtent _ 20.
	ww _ extent x.
	wh _ extent y.
	w _ ww - cornerExtent - cornerExtent.
	h _ wh - cornerExtent - cornerExtent.
	(adjusters at: #topAdjuster) morphPosition: cornerExtent@0 extent: w@thickness.
	(adjusters at: #bottomAdjuster) morphPosition: cornerExtent@(wh-thickness) extent: w@thickness.
	(adjusters at: #leftAdjuster) morphPosition: 0@cornerExtent extent: thickness@h.
	(adjusters at: #rightAdjuster) morphPosition: ww-thickness@cornerExtent extent: thickness@h.
	(adjusters at: #topLeftAdjuster) morphPosition: Point zero extent: cornerExtent@cornerExtent.
	(adjusters at: #bottomLeftAdjuster) morphPosition: 0@(wh-cornerExtent) extent: cornerExtent@cornerExtent.
	(adjusters at: #topRightAdjuster) morphPosition: ww-cornerExtent@0 extent: cornerExtent@cornerExtent.
	(adjusters at: #bottomRightAdjuster) morphPosition: ww@wh-cornerExtent extent: cornerExtent@cornerExtent.

	layoutMorph ifNotNil: [
		pos _ borderWidth @ (borderWidth + self labelHeight).
		layoutMorph
			morphPosition: pos
			extent: extent - pos - borderWidth ].
	
	layoutNeeded _ false! !


!ScrollBar methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:34:35'!
drawOn: aCanvas

	aCanvas
		fillRectangle: (Point zero extent: extent)
		color: (color alphaMixed: 0.3 with: Theme current scrollbarColor)
		borderWidth: borderWidth
		borderStyleSymbol: #simple
		baseColorForBorder: borderColor! !


!MenuMorph methodsFor: 'private' stamp: 'pb 10/30/2016 22:22:53'!
fitInWorld
	"Note: items may not be laid out yet (I found them all to be at 0@0),  
	so we have to add up heights of items above the selected item."

	| delta |
	"If it doesn't fit, show it to the left, not to the right of the hand."
	self morphBoundsInWorld right > owner world morphBoundsInWorld right
		ifTrue: [
			self morphPosition: ((self morphPosition x + 10 - extent x) @ self morphPosition y) ].

	"Make sure that the menu fits in the world."
	delta _ self morphBoundsInWorld amountToTranslateWithin:
		(owner world morphBoundsInWorld withHeight:
			((owner world morphExtentInWorld y) max: (self morphPosition y) + 1)).
	delta = (Point zero) ifFalse: [ self morphPosition: self morphPosition + delta ]! !


!AutoCompleterMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:25:45'!
drawOn: aCanvas
	| rectangle w y0 h y1 y2 scrollbarThickness |
	aCanvas frameAndFillRectangle: (Point zero extent: extent) fillColor: self color borderWidth: borderWidth borderColor: borderColor.
	y0 _ 1.
	w _ extent x-2.
	scrollbarThickness _ ScrollBar scrollbarThickness.
	completer entryCount > self class itemsPerPage  ifTrue: [
		w _ w - scrollbarThickness.
		aCanvas
			frameRectangle: (extent x - scrollbarThickness@0
				extent: scrollbarThickness @ extent y)
			borderWidth: 1
			color: borderColor.
		aCanvas
			image: (BitBltCanvas arrowOfDirection: #up size: scrollbarThickness)
			at: self upButtonPosition.
		aCanvas
			image: (BitBltCanvas arrowOfDirection: #down size: scrollbarThickness)
			at: self downButtonPosition.
		h _ extent y - (2 * scrollbarThickness).
		y1 _ (1.0 * self firstVisible-1 / completer entryCount * h) ceiling + y0 + scrollbarThickness-1.
		y2 _ (1.0 * self lastVisible / completer entryCount * h) floor + y0 + scrollbarThickness -1.
		aCanvas
			fillRectangle: (extent x - scrollbarThickness+2@y1 corner:  extent x-2 @ y2)
			color: Color veryLightGray ].
	self firstVisible
		to: self lastVisible
		do: [ :index |
			rectangle _ 1@y0 extent: w@self class itemHeight.
			index = self selected
				ifTrue: [
					aCanvas fillRectangle: rectangle color: (Theme current listHighlightFocused: true) ].
			aCanvas
				drawString: (completer entries at: index) asString
				at: rectangle topLeft
				font: self class listFont
				color: Theme current text.
			y0 _ y0 + self itemHeight ]! !


!HandMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:27:55'!
drawOn: aCanvas 
	"Draw the hand itself (i.e., the cursor)."
	"This method is only called when we are carrying morphs around..."
	 aCanvas
		stencil: Cursor move
		at: Point zero
		color: Color black! !


!ImageMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:28:02'!
drawOn: aCanvas

	aCanvas image: image at: Point zero! !


!StringMorph methodsFor: 'accessing' stamp: 'pb 10/30/2016 22:35:56'!
fitContents
	"Measures contents later at #minimumExtent"
	self morphExtent: Point zero! !

!StringMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:35:48'!
drawOn: aCanvas
	aCanvas
		drawString: contents
		at: Point zero
		font: self fontToUse
		color: color! !


!IndentingListItemMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:28:12'!
drawOn: aCanvas

	| tRect colorToUse sLeft aForm centeringOffset |
	isHighlighted ifTrue: [
		aCanvas
			fillRectangle: (Point zero extent: extent)
			color: (Theme current
				listHighlightFocused: owner owner hasKeyboardFocus) duller ].
	isSelected ifTrue: [
		aCanvas
			fillRectangle: (Point zero extent: extent)
			color: (Theme current
				listHighlightFocused: owner owner hasKeyboardFocus) ].
			
	tRect _ self toggleRectangle.
	aForm _ isExpanded 
		ifTrue: [ container expandedForm ]
		ifFalse: [ container notExpandedForm ].
	centeringOffset _ ((tRect height - aForm extent y) / 2.0) rounded.

	complexContents hasContents ifTrue: [
		aCanvas 
			image: aForm 
			at: (tRect topLeft translatedBy: 0 @ centeringOffset) ].

	icon isNil
	ifFalse: [
		 aCanvas 
			image: icon
			at:  (tRect topLeft translatedBy:  icon width  @ centeringOffset).
		sLeft _ indentLevel * 12 + 16 + (icon width + 2).
	]
	ifTrue: [
		sLeft _ indentLevel * 12 + 16.
	].
	colorToUse _ complexContents preferredColor ifNil: [ color ].

	aCanvas
		drawString: contents asString
		at: sLeft@0
		font: self fontToUse
		color: colorToUse! !


!MenuItemMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:29:04'!
drawOn: aCanvas 
	| stringColor leftEdge |

	stringColor _ color.
	isSelected & isEnabled
		ifTrue: [
			aCanvas fillRectangle: (Point zero extent: extent) color: Theme current menuHighlight].
	leftEdge _ 0.

	self hasMarker ifTrue: [
		leftEdge _ leftEdge + submorphs first morphWidth + 8 ].

	self hasIcon
		ifTrue: [| iconForm | 
			iconForm _ isEnabled ifTrue: [ self icon ] ifFalse: [ self icon asGrayScaleAndTransparent ].
			aCanvas image: iconForm at: leftEdge+1 @ (extent y - iconForm height // 2).
			leftEdge _ leftEdge + iconForm width + self iconSeparation].

	aCanvas
		drawString: contents
		at: leftEdge @ 1
		font: self fontToUse
		color: stringColor.
	subMenu ifNotNil: [
		aCanvas
			image: self class subMenuMarker
			at: extent x - 8 @ (extent y - self class subMenuMarker height // 2) ]! !


!LayoutAdjustingMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:28:51'!
drawOn: aCanvas

	aCanvas
		fillRectangle: (Point zero extent: extent)
		color: color! !


!LayoutMorph methodsFor: 'layout' stamp: 'pb 10/30/2016 22:28:58'!
layoutBounds
	"Return the bounds for laying out children of the receiver"

	^Point zero extent: extent! !


!HaloHandleMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:27:48'!
drawOn: aCanvas

	aCanvas
		image: (self class circleForm: extent)
		multipliedBy: color
		at: Point zero! !


!InnerListMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:28:23'!
drawBackgroundForMulti: row on: aCanvas
	| selectionDrawBounds c |
	"shade the background darker, if this row is selected"
	selectionDrawBounds _ self drawBoundsForRow: row.
	selectionDrawBounds _ selectionDrawBounds intersect: (Point zero extent: extent).
	c _ (selectedRow notNil and: [ row = selectedRow])
		ifTrue: [ Theme current listHighlightFocused: owner hasKeyboardFocus ]
		ifFalse: [ Theme current listMultiHighlightFocused: owner hasKeyboardFocus ].
	aCanvas fillRectangle: selectionDrawBounds color: c! !

!InnerListMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:28:28'!
drawHighlightOn: aCanvas
"Ademas, poner el mouse pointer de relojito si tarda... Detectarlo automaticamente, etc. Aunque no estoy seguro de como hacerlo... quizas colgar un cachito de codigo en un proceso de mayor prioridad, onda 'si pasa 1 segundo, y todavia no te resetee este flag, entonces pone el relojito'"
	| selectionDrawBounds |
	highlightedRow  ifNil: [ ^self ].
	highlightedRow = 0 ifTrue: [ ^self ].
	selectionDrawBounds _ self drawBoundsForRow: highlightedRow.
	selectionDrawBounds _ selectionDrawBounds intersect: (Point zero extent: extent).
	aCanvas
		fillRectangle: selectionDrawBounds
		color: (Theme current listHighlightFocused: owner hasKeyboardFocus) duller! !

!InnerListMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:28:33'!
drawSelectionOn: aCanvas
	| selectionDrawBounds |
	selectedRow ifNil: [ ^self ].
	selectedRow = 0 ifTrue: [ ^self ].
	selectionDrawBounds _ self drawBoundsForRow: selectedRow.
	selectionDrawBounds _ selectionDrawBounds intersect: (Point zero extent: extent).
	aCanvas
		fillRectangle: selectionDrawBounds
		color: (Theme current listHighlightFocused: owner hasKeyboardFocus)! !


!FillInTheBlankMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:26:59'!
drawOn: aCanvas

	Theme current roundWindowCorners
		ifTrue: [
			aCanvas
				roundRect: (Point zero extent: extent)
				color: color
				radius: Theme current roundedWindowRadius ]
		ifFalse: [ super drawOn: aCanvas ]! !


!MenuLineMorph methodsFor: 'drawing' stamp: 'pb 10/30/2016 22:29:13'!
drawOn: aCanvas 
	| baseColor |
	baseColor _ owner color.
	aCanvas
		fillRectangle: (Point zero corner: extent x @ (extent y / 2))
		color: baseColor twiceDarker.
			
	aCanvas
		fillRectangle: (0 @ (extent y / 2) corner: extent)
		color: baseColor twiceLighter! !


!MorphicEvent methodsFor: 'dispatching' stamp: 'pb 10/30/2016 22:31:30'!
startDispatchFrom: aHand
	"double dispatch the event dispatch"
	"An event of an unknown type was sent. What shall we do?!!"

	Smalltalk beep. 
	self printString displayAt: Point zero.
	self wasHandled: true! !


!MorphicCanvas methodsFor: 'accessing' stamp: 'pb 10/30/2016 22:31:17'!
newClipRect: aRectangleOrNil
	"aRectangle is in world coordinates.
	But ivar clipRect is relative to the form,
	For example, if we had previously been built like
		aCanvas on: someForm over: (100@100 extent 200@100)
	then our origin would be -100 @ -100.
	Then, a clipRect argument like (120@120 extent: 40@30) would mean affecting
	only (20@20 extent: 40@30) in our form"

	self setClipRect: (aRectangleOrNil
		ifNil: [ Point zero corner: form extent ]
		ifNotNil: [ aRectangleOrNil translatedBy: self canvasOrigin ])! !


!MorphicCanvas class methodsFor: 'instance creation' stamp: 'pb 10/30/2016 22:31:24'!
onForm: aForm

	^ self basicNew
		initializeWith: aForm origin: Point zero! !


!TextComposition methodsFor: 'selection' stamp: 'pb 10/30/2016 22:23:23'!
defaultCharacterBlock
	^ CharacterBlock
		stringIndex: 1
		text: model actualContents
		topLeft: lines first topLeft
		extent: Point zero
		textLine: lines first! !


!DifferenceFinder methodsFor: 'private' stamp: 'pb 10/30/2016 22:22:02'!
maxLengthPoints
	| max points |
	max := self maxLength.
	max = 0 ifTrue: [^Array with: Point zero].
	points := OrderedCollection new.
	tally withIndexesDo: [:i :j :t | t = max ifTrue: [points add: i @ j]].
	^points! !

