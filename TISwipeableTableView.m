//
//  TISwipeableTableView.m
//  TISwipeableTableView
//
//  Created by Tom Irving on 28/05/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//

#import "TISwipeableTableView.h"
#import <QuartzCore/QuartzCore.h>

//==========================================================
// - TISwipeableTableViewController
//==========================================================

@interface TISwipeableTableViewController ()
@property (nonatomic, strong) NSIndexPath * indexOfVisibleBackView;
@property (nonatomic, strong) NSIndexPath * indexOfPanningBackView;
@end

@implementation TISwipeableTableViewController
@synthesize indexOfVisibleBackView;

- (id)initWithStyle:(UITableViewStyle)tableViewStyle
{
    self = [super init];
    if (self){
        _tableViewStyle = tableViewStyle;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [self.view bounds].size.width, [self.view bounds].size.height) style:self.tableViewStyle];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    UIPanGestureRecognizer *tableViewPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onTableViewPanned:)];
    [tableViewPanGestureRecognizer setDelegate:self];
    [_tableView addGestureRecognizer:tableViewPanGestureRecognizer];
}

- (void)onTableViewPanned:(UIPanGestureRecognizer*)gesture
{
    CGPoint velocity = [gesture velocityInView:self.tableView];
    UIGestureRecognizerState state = [gesture state];
    
    if (fabs(velocity.x)>fabs(velocity.y))
    {
        CGPoint location = [gesture locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        if (state==UIGestureRecognizerStateBegan)
        {
            self.indexOfPanningBackView = indexPath;
        }
    }

    if (self.indexOfPanningBackView)
    {
        if (state==UIGestureRecognizerStateChanged)
        {
            TISwipeableTableViewCell *cell = (TISwipeableTableViewCell*)[self.tableView cellForRowAtIndexPath:self.indexOfPanningBackView];
            [cell performSelector:@selector(cellWasPanned:) withObject:gesture];
        }
        else if (state==UIGestureRecognizerStateEnded)
        {
            TISwipeableTableViewCell *cell = (TISwipeableTableViewCell*)[self.tableView cellForRowAtIndexPath:self.indexOfPanningBackView];
            [cell performSelector:@selector(cellWasPanned:) withObject:gesture];
            self.indexOfPanningBackView = nil;
        }
    }
    
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    CGPoint velocity = [(UIPanGestureRecognizer*)gestureRecognizer velocityInView:self.tableView];
    if ( fabs(velocity.x) > fabs(velocity.y))
    {
        
        NSString *otherGestureRecognizerClassName = NSStringFromClass([otherGestureRecognizer class]);
        if ([otherGestureRecognizerClassName rangeOfString:@"UIScrollView"].location!=NSNotFound && [otherGestureRecognizerClassName rangeOfString:@"PanGestureRecognizer"].location!=NSNotFound)
        {
            return NO;
        }
        else return YES;
    }
    else
    {
        return YES;
    }

}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return ([indexPath compare:indexOfVisibleBackView] == NSOrderedSame) ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self hideVisibleBackView:YES];
}

- (BOOL)tableView:(UITableView *)tableView shouldSwipeCellAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath {
	
	[self hideVisibleBackView:YES];
	[self setIndexOfVisibleBackView:indexPath];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	[self hideVisibleBackView:YES];
}

- (void)revealBackViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
	
	[self hideVisibleBackView:animated];
	
	if ([cell respondsToSelector:@selector(revealBackViewAnimated:)]){
		[(TISwipeableTableViewCell *)cell revealBackViewAnimated:animated];
		[self setIndexOfVisibleBackView:indexPath];
	}
}

- (void)hideVisibleBackView:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexOfVisibleBackView];
	if ([cell respondsToSelector:@selector(hideBackViewAnimated:)]){
		[(TISwipeableTableViewCell *)cell hideBackViewAnimated:animated];
		[self setIndexOfVisibleBackView:nil];
	}
}


@end

//==========================================================
// - TISwipeableTableViewCell
//==========================================================

@implementation TISwipeableTableViewCellView
- (void)drawRect:(CGRect)rect {
	[(TISwipeableTableViewCell *)self.superview drawContentView:rect];
}
@end

@implementation TISwipeableTableViewCellBackView
- (void)drawRect:(CGRect)rect {
	[(TISwipeableTableViewCell *)self.superview drawBackView:rect];
}

@end

@interface TISwipeableTableViewCell (Private)
- (void)initialSetup;
- (void)resetViews:(BOOL)animated;
- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX;
@end

@implementation TISwipeableTableViewCell
@synthesize backView;
@synthesize contentViewMoving;
@synthesize shouldBounce;

#pragma mark - Init / Overrides
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
		[self initialSetup];
    }
	
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self initialSetup];
	}
	
	return self;
}

- (void)initialSetup {
	
	[self setBackgroundColor:[UIColor clearColor]];
	
	contentView = [[TISwipeableTableViewCellView alloc] initWithFrame:CGRectZero];
	[contentView setClipsToBounds:YES];
	[contentView setOpaque:YES];
	
//	UISwipeGestureRecognizer * swipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(cellWasSwiped:)];
//	[swipeRecognizer setDirection:(UISwipeGestureRecognizerDirectionLeft |
//								   UISwipeGestureRecognizerDirectionRight)];
//	[contentView addGestureRecognizer:swipeRecognizer];
//    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cellWasPanned:)];
//    [contentView addGestureRecognizer:panRecognizer];
	
	backView = [[TISwipeableTableViewCellBackView alloc] initWithFrame:CGRectZero];
	[backView setOpaque:YES];
	[backView setClipsToBounds:YES];
	[backView setHidden:YES];
    
    UISwipeGestureRecognizer *backViewSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onBackViewSwiped:)];
    [backViewSwipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
    [backView addGestureRecognizer:backViewSwipeGestureRecognizer];
    
	
	[self addSubview:backView];
	[self addSubview:contentView];
	
	
	contentViewMoving = NO;
	shouldBounce = YES;
	oldStyle = self.selectionStyle;
}

- (void)prepareForReuse {
	
	[self resetViews:NO];
	[super prepareForReuse];
}

- (void)setFrame:(CGRect)aFrame {
	
	[super setFrame:aFrame];
	
	CGRect newBounds = self.bounds;
	newBounds.size.height -= 1;
	[backView setFrame:newBounds];	
	[contentView setFrame:newBounds];
}

- (void)setNeedsDisplay {
	
	[super setNeedsDisplay];
	if (!contentView.hidden) [contentView setNeedsDisplay];
	if (!backView.hidden) [backView setNeedsDisplay];
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType {
	// Having an accessory buggers swiping right up, so we override.
	// It's easier just to draw the accessory yourself.
}

- (void)setAccessoryView:(UIView *)accessoryView {
	// Same as above.
}

- (void)setHighlighted:(BOOL)highlighted {
	[self setHighlighted:highlighted animated:NO];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
	[super setHighlighted:highlighted animated:animated];
	[self setNeedsDisplay];
}

- (void)setSelected:(BOOL)flag {
	[self setSelected:flag animated:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[super setSelected:selected animated:animated];
	[self setNeedsDisplay];
}

#pragma mark - Subclass Methods
// Implement the following in a subclass
- (void)drawContentView:(CGRect)rect {
	
}

- (void)drawBackView:(CGRect)rect {
	
}

// Optional implementation
- (void)backViewWillAppear:(BOOL)animated {
	
}

- (void)backViewDidAppear:(BOOL)animated {
	
}

- (void)backViewWillDisappear:(BOOL)animated {
	
}

- (void)backViewDidDisappear:(BOOL)animated {
	
}

//===============================//

#pragma mark - Back View Show / Hide

- (void)cellWasPanned:(UIPanGestureRecognizer*)recognizer{
    
    UITableView * tableView = (UITableView *)self.superview;
    
    if ([self.delegate respondsToSelector:@selector(tableView:shouldSwipeCellAtIndexPath:)]){
        
        NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
		
		if ([self.delegate tableView:tableView shouldSwipeCellAtIndexPath:myIndexPath]){
			
            UIGestureRecognizerState state = [recognizer state];
            if (state==UIGestureRecognizerStateBegan)
            {
                
            }
            else if (state==UIGestureRecognizerStateChanged)
            {
                CGPoint translation = [recognizer translationInView:self];
                
                [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                if (translation.x<=0)
                {
                    [contentView.layer setPosition:CGPointMake(translation.x, contentView.layer.position.y)];
                    
                    contentViewMoving = YES;
                    
                    [backView.layer setHidden:NO];
                    [backView setNeedsDisplay];
                    
                    [self backViewWillAppear:NO];
                    
                    oldStyle = self.selectionStyle;
                    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
                }
                else
                {
                    [contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
                }
                

            }
            else if (state==UIGestureRecognizerStateEnded || state==UIGestureRecognizerStateFailed || state==UIGestureRecognizerStateCancelled)
            {
                CGPoint translation = [recognizer translationInView:self];
                if (translation.x < -60)
                {
                    contentViewMoving = NO;
                    backView.layer.hidden = YES;
                    
                    [self revealBackViewAnimated:YES];
                    
                    if ([self.delegate respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
                        [self.delegate tableView:tableView didSwipeCellAtIndexPath:myIndexPath];
                    }
                }
                else
                {
                    [self hideBackViewAnimated:YES];
                }
            }
			
		}

    }
}

- (void)cellWasSwiped:(UISwipeGestureRecognizer *)recognizer {
    
	UITableView * tableView = (UITableView *)self.superview;
	
	if ([self.delegate respondsToSelector:@selector(tableView:shouldSwipeCellAtIndexPath:)]){
	
		NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
		
		if ([self.delegate tableView:tableView shouldSwipeCellAtIndexPath:myIndexPath]){
			
			[self revealBackViewAnimated:YES];
			
			if ([self.delegate respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
				[self.delegate tableView:tableView didSwipeCellAtIndexPath:myIndexPath];
			}
		}
	}
}

- (void)onBackViewSwiped:(UISwipeGestureRecognizer*)gesture
{
    [self hideBackViewAnimated:YES];
}

- (void)revealBackViewAnimated:(BOOL)animated {
	
	if (!contentViewMoving && backView.hidden){
		contentViewMoving = YES;
		
		[backView.layer setHidden:NO];
		[backView setNeedsDisplay];
		
		[self backViewWillAppear:animated];
		
		oldStyle = self.selectionStyle;
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		[contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
		[contentView.layer setPosition:CGPointMake(-contentView.frame.size.width, contentView.layer.position.y)];
    
		if (animated){
			
			CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
			[animation setRemovedOnCompletion:NO];
			[animation setDelegate:self];
			[animation setDuration:0.14];
			[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
			[contentView.layer addAnimation:animation forKey:@"reveal"];
		}
		else
		{
			[self backViewDidAppear:animated];
			[self setSelected:NO];
			
			contentViewMoving = NO;
		}
	}
}

- (void)hideBackViewAnimated:(BOOL)animated {
	
	if (!backView.hidden){
		
		contentViewMoving = YES;
		
		[self backViewWillDisappear:animated];
		
		if (animated){
			
			CGFloat hideDuration = 0.09;
			
			[backView.layer setOpacity:0.0];
			CABasicAnimation * hideAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
			[hideAnimation setFromValue:[NSNumber numberWithFloat:1.0]];
			[hideAnimation setToValue:[NSNumber numberWithFloat:0.0]];
			[hideAnimation setDuration:hideDuration];
			[hideAnimation setRemovedOnCompletion:NO];
			[hideAnimation setDelegate:self];
			[backView.layer addAnimation:hideAnimation forKey:@"hide"];
			
			CGFloat originalX = contentView.layer.position.x;
			[contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
			[contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
			[contentView.layer addAnimation:[self bounceAnimationWithHideDuration:hideDuration initialXOrigin:originalX] 
									 forKey:@"bounce"];
			
			
		}
		else
		{
			[self resetViews:NO];
		}
	}
}

- (void)resetViews:(BOOL)animated {
	
	[contentView.layer removeAllAnimations];
	[backView.layer removeAllAnimations];
	
	contentViewMoving = NO;
	
	[contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
	[contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
	
	[backView.layer setHidden:YES];
	[backView.layer setOpacity:1.0];
	
	[self setSelectionStyle:oldStyle];
	
	[self backViewDidDisappear:animated];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	
	if (anim == [contentView.layer animationForKey:@"reveal"]){
		[contentView.layer removeAnimationForKey:@"reveal"];
		
		[self backViewDidAppear:YES];
		[self setSelected:NO];
		
		contentViewMoving = NO;
	}
	
	if (anim == [contentView.layer animationForKey:@"bounce"]){
		[contentView.layer removeAnimationForKey:@"bounce"];
		[self resetViews:YES];
	}
	
	if (anim == [backView.layer animationForKey:@"hide"]){
		[backView.layer removeAnimationForKey:@"hide"];
	}
}

- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX {
	
	CABasicAnimation * animation0 = [CABasicAnimation animationWithKeyPath:@"position.x"];
	[animation0 setFromValue:[NSNumber numberWithFloat:originalX]];
	[animation0 setToValue:[NSNumber numberWithFloat:0]];
	[animation0 setDuration:hideDuration];
	[animation0 setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
	[animation0 setBeginTime:0];
	
	CAAnimationGroup * hideAnimations = [CAAnimationGroup animation];
	[hideAnimations setAnimations:[NSArray arrayWithObject:animation0]];
	
	CGFloat fullDuration = hideDuration;
	
	if (shouldBounce){
		
		CGFloat bounceDuration = 0.04;
		
		CABasicAnimation * animation1 = [CABasicAnimation animationWithKeyPath:@"position.x"];
		[animation1 setFromValue:[NSNumber numberWithFloat:0]];
		[animation1 setToValue:[NSNumber numberWithFloat:-20]];
		[animation1 setDuration:bounceDuration];
		[animation1 setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
		[animation1 setBeginTime:hideDuration];
		
		CABasicAnimation * animation2 = [CABasicAnimation animationWithKeyPath:@"position.x"];
		[animation2 setFromValue:[NSNumber numberWithFloat:-20]];
		[animation2 setToValue:[NSNumber numberWithFloat:15]];
		[animation2 setDuration:bounceDuration];
		[animation2 setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
		[animation2 setBeginTime:(hideDuration + bounceDuration)];
		
		CABasicAnimation * animation3 = [CABasicAnimation animationWithKeyPath:@"position.x"];
		[animation3 setFromValue:[NSNumber numberWithFloat:15]];
		[animation3 setToValue:[NSNumber numberWithFloat:0]];
		[animation3 setDuration:bounceDuration];
		[animation3 setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
		[animation3 setBeginTime:(hideDuration + (bounceDuration * 2))];
		
		[hideAnimations setAnimations:[NSArray arrayWithObjects:animation0, animation1, animation2, animation3, nil]];
		
		fullDuration = hideDuration + (bounceDuration * 3);
	}
	
	[hideAnimations setDuration:fullDuration];
	[hideAnimations setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
	[hideAnimations setDelegate:self];
	[hideAnimations setRemovedOnCompletion:NO];
	
	return hideAnimations;
}

#pragma mark - Other
- (NSString *)description {
	
	NSString * extraInfo = backView.hidden ? @"ContentView visible": @"BackView visible";
	return [NSString stringWithFormat:@"<TISwipeableTableViewCell %p; '%@'>", self, extraInfo];
}

@end
