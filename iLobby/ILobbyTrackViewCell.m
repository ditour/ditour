//
//  ILobbyTrackViewCell.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/23/12.
//  Copyright (c) 2012 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyTrackViewCell.h"



// background view to display when the cell is selected
@interface ILobbyTrackBackgroundView : UIView

@property (nonatomic, readonly, strong) UIColor *strokeColor;
@property (nonatomic, readonly, strong) UIColor *fillColor;

- (id)initWithFrame:(CGRect)frame stroke:(UIColor *)strokeColor fill:(UIColor *)fillColor;
+ (id)backgroundViewWithStroke:(UIColor *)strokeColor fill:(UIColor *)fillColor;

@end



@implementation ILobbyTrackViewCell

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        // change to our custom selected background view
        ILobbyTrackBackgroundView *backgroundView = [ILobbyTrackBackgroundView backgroundViewWithStroke:[UIColor blackColor] fill:[UIColor colorWithRed:0.8 green:0.8 blue:1.0 alpha:0.9]];
        self.selectedBackgroundView = backgroundView;
    }
    return self;
}


- (void)setOutlined:(BOOL)outlined {
	_outlined = outlined;
	self.backgroundView = outlined ? [ILobbyTrackBackgroundView backgroundViewWithStroke:[UIColor whiteColor] fill:[UIColor blackColor]] : nil;
}

@end



@interface ILobbyTrackBackgroundView ()
@property (nonatomic, readwrite, strong) UIColor *strokeColor;
@property (nonatomic, readwrite, strong) UIColor *fillColor;
@end


// code modified from Apple's "CollectionView-Simple" sample code
@implementation ILobbyTrackBackgroundView

- (id)initWithFrame:(CGRect)frame stroke:(UIColor *)strokeColor fill:(UIColor *)fillColor {
    self = [super initWithFrame:frame];
    if (self) {
		self.strokeColor = strokeColor;
		self.fillColor = fillColor;
    }
    return self;
}


+ (id)backgroundViewWithStroke:(UIColor *)strokeColor fill:(UIColor *)fillColor {
	return [[ILobbyTrackBackgroundView alloc] initWithFrame:CGRectZero stroke:strokeColor fill:fillColor];
}


- (void)drawRect:(CGRect)rect {
    // draw a rounded rect bezier path
    CGContextRef aRef = UIGraphicsGetCurrentContext();
    CGContextSaveGState(aRef);
    UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:5.0f];
    [bezierPath setLineWidth:5.0f];
	[self.fillColor setFill];
	[bezierPath fill];
    [self.strokeColor setStroke];
    [bezierPath stroke];
    CGContextRestoreGState(aRef);
}

@end
