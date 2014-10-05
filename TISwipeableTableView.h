//
//  TISwipeableTableView.h
//  TISwipeableTableView
//
//  Created by Tom Irving on 28/05/2010.
//  Copyright 2010 Tom Irving. All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without modification,
//	are permitted provided that the following conditions are met:
//
//		1. Redistributions of source code must retain the above copyright notice, this list of
//		   conditions and the following disclaimer.
//
//		2. Redistributions in binary form must reproduce the above copyright notice, this list
//         of conditions and the following disclaimer in the documentation and/or other materials
//         provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY TOM IRVING "AS IS" AND ANY EXPRESS OR IMPLIED
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOM IRVING OR
//	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import <UIKit/UIKit.h>

//==========================================================
// - TISwipeableTableViewController
//==========================================================

NSString * const TISwipeableTableViewBackViewWillAppear;
NSString * const TISwipeableTableViewBackViewDidAppear;

// Notification posted when a row is selected
NSString * const TISwipeableTableViewDidSelectRow;

	// User info keys posted along with the above notification
	NSString * const TISwipeableTableViewSelectedPathKey; // The selected index path
	NSString * const TISwipeableTableViewVisiblePathsKey; // All index paths


@interface TISwipeableTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSIndexPath * indexOfVisibleBackView;
@property (nonatomic, strong) NSIndexPath * indexOfPanningBackView;
@property (nonatomic, assign) UITableViewStyle tableViewStyle;
@property (nonatomic, strong) UIPanGestureRecognizer *tableLeftPanGestureRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *tableRightPanGestureRecognizer;
@property (nonatomic, retain) UIRefreshControl *refreshControl;

- (id)initWithStyle:(UITableViewStyle)tableViewStyle;

// Thanks to Martin Destagnol (@mdestagnol) for this method.
- (BOOL)tableView:(UITableView *)tableView shouldSwipeCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath;

- (void)revealBackViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)hideBackViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)hideVisibleBackView:(BOOL)animated;

- (Class)tableLeftPanGestureRecognizerClass;
- (Class)tableRightPanGestureRecognizerClass;

@end

//==========================================================
// - TISwipeableTableViewCell
//==========================================================

@interface TISwipeableTableViewCellView : UIView
@end

@interface TISwipeableTableViewCellBackView : UIView
@end

@protocol TISwipeableTableViewCellDelegate <NSObject>
- (BOOL)tableView:(UITableView *)tableView shouldSwipeCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSwipeCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)hideBackViewAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;
@end

@interface TISwipeableTableViewCell : UITableViewCell <UIGestureRecognizerDelegate> {
	
	UIView * contentView;
	UIView * backView;
	
	BOOL contentViewMoving;
	BOOL shouldBounce;
	
	UITableViewCellSelectionStyle oldStyle;
}

@property (nonatomic, readonly) UIView * backView;
@property (nonatomic, assign) BOOL contentViewMoving;
@property (nonatomic, assign) BOOL shouldBounce;
@property (nonatomic, assign) CGFloat backViewInset;
@property (nonatomic, unsafe_unretained) id<TISwipeableTableViewCellDelegate> delegate;

- (void)drawContentView:(CGRect)rect;
- (void)drawBackView:(CGRect)rect;

- (void)backViewWillAppear:(BOOL)animated;
- (void)backViewDidAppear:(BOOL)animated;
- (void)backViewWillDisappear:(BOOL)animated;
- (void)backViewDidDisappear:(BOOL)animated;

- (void)revealBackViewAnimated:(BOOL)animated;
- (void)hideBackViewAnimated:(BOOL)animated;

- (void)cellWasPanned:(UIPanGestureRecognizer*)recognizer;
- (void)cellWasPannedWithTranslation:(CGPoint)translation state:(UIGestureRecognizerState)state;

- (void)resetViews:(BOOL)animated;

@end
