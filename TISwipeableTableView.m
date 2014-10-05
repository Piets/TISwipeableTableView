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

NSString * const TISwipeableTableViewBackViewWillAppear = @"TISwipeableTableViewBackViewWillAppear";
NSString * const TISwipeableTableViewBackViewDidAppear = @"TISwipeableTableViewBackViewDidAppear";

NSString * const TISwipeableTableViewDidSelectRow = @"TISwipeableTableViewDidSelectRow";
	NSString * const TISwipeableTableViewSelectedPathKey = @"TISwipeableTableViewSelectedPath";
	NSString * const TISwipeableTableViewVisiblePathsKey = @"TISwipeableTableViewVisiblePaths";

@interface TISwipeableTableViewController ()
//@property (nonatomic, strong) NSIndexPath * indexOfVisibleBackView;
//@property (nonatomic, strong) NSIndexPath * indexOfPanningBackView;
@end

@implementation TISwipeableTableViewController
@synthesize indexOfVisibleBackView;
@synthesize indexOfPanningBackView;

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
    
    self.tableLeftPanGestureRecognizer = [[[self tableLeftPanGestureRecognizerClass] alloc] initWithTarget:self action:@selector(onTableViewPanned:)];
    [self.tableLeftPanGestureRecognizer setDelegate:self];
    [_tableView addGestureRecognizer:self.tableLeftPanGestureRecognizer];
    
    self.tableRightPanGestureRecognizer = [[[self tableRightPanGestureRecognizerClass] alloc] initWithTarget:self action:@selector(onTableViewPanned:)];
    [self.tableRightPanGestureRecognizer setDelegate:self];
    [_tableView addGestureRecognizer:self.tableRightPanGestureRecognizer];
}

- (Class)tableLeftPanGestureRecognizerClass
{
    return [UIPanGestureRecognizer class];
}

- (Class)tableRightPanGestureRecognizerClass
{
    return [UIPanGestureRecognizer class];
}

- (void)onTableViewPanned:(UIPanGestureRecognizer*)gesture
{
    CGPoint velocity = [gesture velocityInView:self.tableView];
    UIGestureRecognizerState state = [gesture state];
    
    if (self.tableView.isDragging)
    {
        [gesture setEnabled:NO];
        [gesture setEnabled:YES];
        
        [self hideVisibleBackView:YES];
    }

    if (fabs(velocity.x)>fabs(velocity.y))
    {
        CGPoint location = [gesture locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
        if (state==UIGestureRecognizerStateBegan)
        {
            if (velocity.x>=0)
            {
                // check if this condition is correct
                if (self.indexOfVisibleBackView)
                {
                    [self checkThatIndexOfVisibleBackViewIsValid];
                }
                
                if ([self.indexOfVisibleBackView isEqual:indexPath])
                {
                    self.indexOfPanningBackView = nil;
                }
                else
                {
                    if (![self.tableView isDecelerating])
                    {
                        self.indexOfPanningBackView = indexPath;
                        TISwipeableTableViewCell *cell = (TISwipeableTableViewCell*)[self.tableView cellForRowAtIndexPath:self.indexOfPanningBackView];
                        if ([cell respondsToSelector:@selector(cellWasPanned:)]){
                            [cell performSelector:@selector(cellWasPanned:) withObject:gesture];
                        }
                    }
                }
            }
            else
            {
                if ([self.indexOfVisibleBackView isEqual:indexPath])
                {
                    TISwipeableTableViewCell *cell = (TISwipeableTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                    if ([cell respondsToSelector:@selector(onBackViewSwiped:)]){
                        [cell performSelector:@selector(onBackViewSwiped:) withObject:gesture];
                        //[self setIndexOfVisibleBackView:nil];
                    }
                }
                
            }
        }
    }

    if (self.indexOfPanningBackView)
    {
        if (state==UIGestureRecognizerStateChanged)
        {
            TISwipeableTableViewCell *cell = (TISwipeableTableViewCell*)[self.tableView cellForRowAtIndexPath:self.indexOfPanningBackView];
            if ([cell respondsToSelector:@selector(cellWasPanned:)]){
                [cell performSelector:@selector(cellWasPanned:) withObject:gesture];
            }
        }
        else if (state==UIGestureRecognizerStateEnded || state==UIGestureRecognizerStateCancelled || state==UIGestureRecognizerStateFailed)
        {
            TISwipeableTableViewCell *cell = (TISwipeableTableViewCell*)[self.tableView cellForRowAtIndexPath:self.indexOfPanningBackView];
            if ([cell respondsToSelector:@selector(cellWasPanned:)]){
                [cell performSelector:@selector(cellWasPanned:) withObject:gesture];
            }
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
//    if (self.indexOfVisibleBackView)
//    {
//        [self hideVisibleBackView:YES];
//    }
//    
    [self setIndexOfVisibleBackView:nil];
    [self setIndexOfPanningBackView:nil];
    return 1;
}

- (void)checkThatIndexOfVisibleBackViewIsValid
{
    TISwipeableTableViewCell *cell = (TISwipeableTableViewCell*)[self.tableView cellForRowAtIndexPath:indexOfVisibleBackView];
    if ([cell isKindOfClass:[TISwipeableTableViewCell class]])
    {
        // check of make sure that the content view is visible
        // if the back view is hidden, it means content view is visible
        // so the state is wrong
        if (cell.backView.hidden)
        {
            [self setIndexOfVisibleBackView:nil];
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    // same index path
    if ([indexPath compare:indexOfVisibleBackView] == NSOrderedSame)
    {
        [self checkThatIndexOfVisibleBackViewIsValid];
        if (indexOfVisibleBackView)
        {
            return nil;
        }
        else
        {
            return indexPath;
        }
    }
    
    // different index path
    else
    {
        return indexPath;
    }
    
//    return ([indexPath compare:indexOfVisibleBackView] == NSOrderedSame) ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self hideVisibleBackView:YES];
	
	NSNotificationCenter* notifCenter = [NSNotificationCenter defaultCenter];
	
	[notifCenter postNotificationName:TISwipeableTableViewDidSelectRow
							   object:self
							 userInfo:
	 @{TISwipeableTableViewSelectedPathKey : indexPath,
	TISwipeableTableViewVisiblePathsKey : [tableView indexPathsForVisibleRows]}];
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

- (void)hideBackViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    [self setIndexOfVisibleBackView:nil];
}

- (void)hideVisibleBackView:(BOOL)animated {
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexOfVisibleBackView];
	if ([cell respondsToSelector:@selector(hideBackViewAnimated:)]){
		[(TISwipeableTableViewCell *)cell hideBackViewAnimated:animated];
		//[self setIndexOfVisibleBackView:nil];
	}
}


@end

//==========================================================
// - TISwipeableTableViewCell
//==========================================================

@implementation TISwipeableTableViewCellView
- (void)drawRect:(CGRect)rect {
    if ([self.superview isKindOfClass:[TISwipeableTableViewCell class]])
    {
        [(TISwipeableTableViewCell *)self.superview drawContentView:rect];
    }
	else if ([self.superview.superview isKindOfClass:[TISwipeableTableViewCell class]])
    {
        [(TISwipeableTableViewCell *)self.superview.superview drawContentView:rect];
    }
}
@end

@implementation TISwipeableTableViewCellBackView
- (void)drawRect:(CGRect)rect {
    if ([self.superview isKindOfClass:[TISwipeableTableViewCell class]])
    {
        [(TISwipeableTableViewCell *)self.superview drawBackView:rect];
    }
	else if ([self.superview.superview isKindOfClass:[TISwipeableTableViewCell class]])
    {
        [(TISwipeableTableViewCell *)self.superview.superview drawBackView:rect];
    }
	
}

@end

@interface TISwipeableTableViewCell (Private)
- (void)initialSetup;
- (void)resetViews:(BOOL)animated;
- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX finalXOrigin:(CGFloat)finalX;
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
    
//    UISwipeGestureRecognizer *backViewSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onBackViewSwiped:)];
//    [backViewSwipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
//    [backView addGestureRecognizer:backViewSwipeGestureRecognizer];
    
	
	[self addSubview:backView];
	[self addSubview:contentView];
	
	
	contentViewMoving = NO;
	shouldBounce = YES;
	oldStyle = self.selectionStyle;
	self.backViewInset = 0.f;
}

- (void)prepareForReuse {
	
	[self resetViews:NO];
	[super prepareForReuse];
}

- (void)setFrame:(CGRect)aFrame {
	
	[super setFrame:aFrame];
	
	CGRect newBounds = self.bounds;
	//newBounds.size.height -= 1;
//	[backView setFrame:newBounds];	
	[contentView setFrame:newBounds];
    
    CGRect backViewBounds = newBounds;
//    backViewBounds.size.width += 100;
	backViewBounds.origin.x = -backViewBounds.size.width;
    [backView setFrame:backViewBounds];
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

- (void)cellWasPanned:(UIPanGestureRecognizer*)recognizer
{
    UIGestureRecognizerState state = recognizer.state;
    CGPoint translation = [recognizer translationInView:self];
    
    [self cellWasPannedWithTranslation:translation state:state];
}

- (void)cellWasPannedWithTranslation:(CGPoint)translation state:(UIGestureRecognizerState)state
{
    UITableView * tableView = (UITableView *)self.superview;
    if (![tableView isKindOfClass:[UITableView class]])
    {
        tableView = (UITableView *)self.superview.superview;
    }
    
    TISwipeableTableViewController *viewController = [self viewController];
    if ([viewController respondsToSelector:@selector(tableView:shouldSwipeCellAtIndexPath:)]){
        
        NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
		
		if ([viewController tableView:tableView shouldSwipeCellAtIndexPath:myIndexPath]){
			
//            UIGestureRecognizerState state = [recognizer state];
            if (state==UIGestureRecognizerStateBegan)
            {
                if ([viewController respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
                    [viewController tableView:tableView didSwipeCellAtIndexPath:myIndexPath];
                }
                [self backViewWillAppear:NO];
            }
            else if (state==UIGestureRecognizerStateChanged)
            {
//                CGPoint translation = [recognizer translationInView:self];
                
                [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [backView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                if (translation.x >= 0)
                {
                    [contentView.layer setPosition:CGPointMake(translation.x, contentView.layer.position.y)];
                    [backView.layer setPosition:CGPointMake(translation.x - backView.layer.bounds.size.width + self.backViewInset , contentView.layer.position.y)];
                    
                    contentViewMoving = YES;
                    
                    [backView.layer setHidden:NO];
                    [backView setNeedsDisplay];

                    oldStyle = self.selectionStyle;
                    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
                    [self onContentViewAndBackViewPanned:CGPointMake(translation.x, contentView.layer.position.y)];
                }
                else
                {
                    [contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
                    [backView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
                    [self onContentViewAndBackViewPanned:CGPointMake(0, contentView.layer.position.y)];
                }

            }
            else if (state==UIGestureRecognizerStateEnded || state==UIGestureRecognizerStateFailed || state==UIGestureRecognizerStateCancelled)
            {
//                CGPoint translation = [recognizer translationInView:self];
                if (translation.x > [self thresholdToHideBackView])
                {
                    contentViewMoving = NO;
                    backView.layer.hidden = YES;
                    
                    [self onRevealingBackViewFromPosition:backView.layer.position];
                    [self revealBackViewAnimated:YES];
                    
                }
                else
                {
                    
                    [self hideBackViewAnimated:YES];
                    
                }
            }
			
		}

    }
}

- (void)onRevealingBackViewFromPosition:(CGPoint)position
{
    
}

- (TISwipeableTableViewController*)viewController
{
    for (UIView *next = [self superview]; next; next = next.superview)
    {
        UIResponder *nextResponder = [next nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
        {
            return (TISwipeableTableViewController*)nextResponder;
        }
    }
    
    return (TISwipeableTableViewController*)self.delegate;
}

- (float)thresholdToHideBackView
{
    return 60.0;
}

- (void)onContentViewAndBackViewPanned:(CGPoint)translation
{
    
}

- (void)cellWasSwiped:(UISwipeGestureRecognizer *)recognizer {
    
	UITableView * tableView = (UITableView *)self.superview;
    if (![tableView isKindOfClass:[UITableView class]])
    {
        tableView = (UITableView *)self.superview.superview;
    }
	
    TISwipeableTableViewController *viewController = [self viewController];
	if ([viewController respondsToSelector:@selector(tableView:shouldSwipeCellAtIndexPath:)]){
	
		NSIndexPath * myIndexPath = [tableView indexPathForCell:self];
		
		if ([viewController tableView:tableView shouldSwipeCellAtIndexPath:myIndexPath]){
			
			[self revealBackViewAnimated:YES];
			
            if ([viewController respondsToSelector:@selector(tableView:didSwipeCellAtIndexPath:)]){
				[viewController tableView:tableView didSwipeCellAtIndexPath:myIndexPath];
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
		
		NSNotificationCenter* notifCenter = [NSNotificationCenter defaultCenter];
		
		[self backViewWillAppear:animated];
		[notifCenter postNotificationName:TISwipeableTableViewBackViewWillAppear object:self];
		
		oldStyle = self.selectionStyle;
		[self setSelectionStyle:UITableViewCellSelectionStyleNone];
		
		
    
		if (animated){
            
            float ratio = contentView.frame.origin.x/ (self.frame.size.width - self.backViewInset);
            float duration = 0.1 + 0.25 * ratio;
            float damping = 0.7f + 0.5f * (1-ratio);
            float velocity = 0.2f;
            
            [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:damping initialSpringVelocity:velocity options:UIViewAnimationCurveLinear animations:^{
            
                [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [backView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [contentView.layer setPosition:CGPointMake(contentView.frame.size.width-self.backViewInset, contentView.layer.position.y)];
                [backView.layer setPosition:CGPointMake(0.f, contentView.layer.position.y)];
                
            } completion:^(BOOL finished) {
                
                [self backViewDidAppear:YES];
                [self setSelected:NO];
                
                contentViewMoving = NO;
                
            }];

//			CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
//			[animation setRemovedOnCompletion:NO];
//			[animation setDelegate:self];
//			[animation setDuration:0.14];
//            CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithControlPoints:0.74 :0.0 :0.74 :0.19];
//			[animation setTimingFunction:function];
//            //[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
//			[contentView.layer addAnimation:animation forKey:@"reveal"];
//            [backView.layer addAnimation:animation forKey:@"reveal"];
		}
		else
		{
            [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
            [backView.layer setAnchorPoint:CGPointMake(0, 0.5)];
            [contentView.layer setPosition:CGPointMake(contentView.frame.size.width-self.backViewInset, contentView.layer.position.y)];
            [backView.layer setPosition:CGPointMake(0.f, contentView.layer.position.y)];
            
			[self backViewDidAppear:animated];
			[notifCenter postNotificationName:TISwipeableTableViewBackViewDidAppear object:self];
			
			[self setSelected:NO];
			
			contentViewMoving = NO;
		}
	}
}

- (void)hideBackViewAnimated:(BOOL)animated {
	
	if (!backView.hidden){
		
		contentViewMoving = YES;
		
		[self backViewWillDisappear:animated];
        
        TISwipeableTableViewController *viewController = [self viewController];
        if ([viewController respondsToSelector:@selector(hideBackViewAtIndexPath:animated:)])
        {
            UITableView * tableView = (UITableView *)self.superview;
            if (![tableView isKindOfClass:[UITableView class]])
            {
                tableView = (UITableView *)self.superview.superview;
            }
            NSIndexPath *indexPath = [tableView indexPathForCell:self];
            [viewController hideBackViewAtIndexPath:indexPath animated:YES];
        }
		
		if (animated){
			
//			CGFloat hideDuration = 0.15;
//			
//			CGFloat originalX = contentView.layer.position.x;
//			[contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
//			[contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
//			[contentView.layer addAnimation:[self bounceAnimationWithHideDuration:hideDuration initialXOrigin:originalX finalXOrigin:0]
//									 forKey:@"bounce"];
//            
//            CGFloat backViewOriginalX = backView.layer.position.x;
//            [backView.layer setAnchorPoint:CGPointMake(0, 0.5)];
//			[backView.layer setPosition:CGPointMake(self.frame.size.width, contentView.layer.position.y)];
//			[backView.layer addAnimation:[self bounceAnimationWithHideDuration:hideDuration initialXOrigin:backViewOriginalX finalXOrigin:self.frame.size.width] forKey:@"bounce"];
            
            
            float duration = 0.35;
            float damping = 0.6f;
            float velocity = 0.2f;
            
            [UIView animateWithDuration:duration delay:0.0 usingSpringWithDamping:damping initialSpringVelocity:velocity options:UIViewAnimationCurveLinear animations:^{
                
                [contentView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [contentView.layer setPosition:CGPointMake(0, contentView.layer.position.y)];
                
                [backView.layer setAnchorPoint:CGPointMake(0, 0.5)];
                [backView.layer setPosition:CGPointMake(-self.frame.size.width, contentView.layer.position.y)];
                
            } completion:^(BOOL finished) {
                [self resetViews:YES];
            }];
			
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
    
    [backView.layer setAnchorPoint:CGPointMake(0, 0.5)];
	[backView.layer setPosition:CGPointMake(-self.frame.size.width, contentView.layer.position.y)];
	
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

- (CAAnimationGroup *)bounceAnimationWithHideDuration:(CGFloat)hideDuration initialXOrigin:(CGFloat)originalX finalXOrigin:(CGFloat)finalX
{
	CABasicAnimation * animation0 = [CABasicAnimation animationWithKeyPath:@"position.x"];
	[animation0 setFromValue:[NSNumber numberWithFloat:originalX]];
	[animation0 setToValue:[NSNumber numberWithFloat:finalX]];
	[animation0 setDuration:hideDuration];
	//CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithControlPoints:0.241 :0.348 :0.532 :0.754];
    //[animation0 setTimingFunction:function];
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
