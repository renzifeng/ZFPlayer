//
//  UIScrollView+ZFPlayer.m
//  ZFPlayer
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "UIScrollView+ZFPlayer.h"
#import <objc/runtime.h>
#import "ZFReachabilityManager.h"
#import "ZFPlayerConst.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

@interface UIScrollView ()

@property (nonatomic) CGFloat zf_lastOffsetY;
@property (nonatomic) CGFloat zf_lastOffsetX;
@property (nonatomic) ZFPlayerScrollDirection zf_scrollDirection;

@end

@implementation UIScrollView (ZFPlayer)

#pragma mark - public method

- (UIView *)zf_getCellForIndexPath:(NSIndexPath *)indexPath {
    if ([self _isTableView]) {
        UITableView *tableView = (UITableView *)self;
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        return cell;
    } else if ([self _isCollectionView]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
        return cell;
    }
    return nil;
}

- (NSIndexPath *)zf_getIndexPathForCell:(UIView *)cell {
    if ([self _isTableView]) {
        UITableView *tableView = (UITableView *)self;
        NSIndexPath *indexPath = [tableView indexPathForCell:(UITableViewCell *)cell];
        return indexPath;
    } else if ([self _isCollectionView]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        NSIndexPath *indexPath = [collectionView indexPathForCell:(UICollectionViewCell *)cell];
        return indexPath;
    }
    return nil;
}

/**
Scroll to indexPath with position.
 
@param indexPath scroll the  indexPath.
@param scrollPosition  scrollView scroll position.
@param animated animate.
@param completionHandler  Scroll completion callback.
*/
- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath
                 atScrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                         animated:(BOOL)animated
                completionHandler:(void (^ __nullable)(void))completionHandler {
    [self zf_scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animateDuration:animated ? 0.4 : 0.0 completionHandler:completionHandler];
}

- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath
                 atScrollPosition:(ZFPlayerScrollViewScrollPosition)scrollPosition
                  animateDuration:(NSTimeInterval)duration
                completionHandler:(void (^ __nullable)(void))completionHandler {
    BOOL animated = duration > 0.0;
    if ([self _isTableView]) {
        UITableView *tableView = (UITableView *)self;
        UITableViewScrollPosition tableScrollPosition = UITableViewScrollPositionNone;
        if (scrollPosition <= ZFPlayerScrollViewScrollPositionBottom) {
            tableScrollPosition = (UITableViewScrollPosition)scrollPosition;
        }
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:tableScrollPosition animated:animated];
    } else if ([self _isCollectionView]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        if (self.zf_scrollViewDirection == ZFPlayerScrollViewDirectionVertical) {
            UICollectionViewScrollPosition collectionScrollPosition = UICollectionViewScrollPositionNone;
            switch (scrollPosition) {
                case ZFPlayerScrollViewScrollPositionNone:
                    collectionScrollPosition = UICollectionViewScrollPositionNone;
                    break;
                case ZFPlayerScrollViewScrollPositionTop:
                    collectionScrollPosition = UICollectionViewScrollPositionTop;
                    break;
                case ZFPlayerScrollViewScrollPositionCenteredVertically:
                    collectionScrollPosition = UICollectionViewScrollPositionCenteredVertically;
                    break;
                case ZFPlayerScrollViewScrollPositionBottom:
                    collectionScrollPosition = UICollectionViewScrollPositionBottom;
                    break;
                default:
                    break;
            }
            [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:collectionScrollPosition animated:animated];
        } else if (self.zf_scrollViewDirection == ZFPlayerScrollViewDirectionHorizontal) {
            UICollectionViewScrollPosition collectionScrollPosition = UICollectionViewScrollPositionNone;
            switch (scrollPosition) {
                case ZFPlayerScrollViewScrollPositionNone:
                    collectionScrollPosition = UICollectionViewScrollPositionNone;
                    break;
                case ZFPlayerScrollViewScrollPositionLeft:
                    collectionScrollPosition = UICollectionViewScrollPositionLeft;
                    break;
                case ZFPlayerScrollViewScrollPositionCenteredHorizontally:
                    collectionScrollPosition = UICollectionViewScrollPositionCenteredHorizontally;
                    break;
                case ZFPlayerScrollViewScrollPositionRight:
                    collectionScrollPosition = UICollectionViewScrollPositionRight;
                    break;
                default:
                    break;
            }
            [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:collectionScrollPosition animated:animated];
        }
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completionHandler) completionHandler();
    });
}

- (void)zf_scrollViewDidEndDecelerating {
    BOOL scrollToScrollStop = !self.tracking && !self.dragging && !self.decelerating;
    if (scrollToScrollStop) {
        [self _scrollViewDidStopScroll];
    }
}

- (void)zf_scrollViewDidEndDraggingWillDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        BOOL dragToDragStop = self.tracking && !self.dragging && !self.decelerating;
        if (dragToDragStop) {
            [self _scrollViewDidStopScroll];
        }
    }
}

- (void)zf_scrollViewDidScrollToTop {
    [self _scrollViewDidStopScroll];
}

- (void)zf_scrollViewDidScroll {
    if (self.zf_scrollViewDirection == ZFPlayerScrollViewDirectionVertical) {
        [self _findCorrectCellWhenScrollViewDirectionVertical:nil];
        [self _scrollViewScrollingDirectionVertical];
    } else {
        [self _findCorrectCellWhenScrollViewDirectionHorizontal:nil];
        [self _scrollViewScrollingDirectionHorizontal];
    }
}

- (void)zf_scrollViewWillBeginDragging {
    [self _scrollViewBeginDragging];
}

#pragma mark - private method

- (void)_scrollViewDidStopScroll {
    self.zf_scrollDirection = ZFPlayerScrollDirectionNone;
    @zf_weakify(self)
    [self zf_filterShouldPlayCellWhileScrolled:^(NSIndexPath * _Nonnull indexPath) {
        @zf_strongify(self)
        if (self.zf_scrollViewDidStopScrollCallback) self.zf_scrollViewDidStopScrollCallback(indexPath);
        if (self.zf_scrollViewDidEndScrollingCallback) self.zf_scrollViewDidEndScrollingCallback(indexPath);
    }];
}

- (void)_scrollViewBeginDragging {
    if (self.zf_scrollViewDirection == ZFPlayerScrollViewDirectionVertical) {
        self.zf_lastOffsetY = self.contentOffset.y;
    } else {
        self.zf_lastOffsetX = self.contentOffset.x;
    }
}

/**
  The percentage of scrolling processed in vertical scrolling.
 */
- (void)_scrollViewScrollingDirectionVertical {
    CGFloat offsetY = self.contentOffset.y;
    self.zf_scrollDirection = (offsetY - self.zf_lastOffsetY > 0) ? ZFPlayerScrollDirectionUp : ZFPlayerScrollDirectionDown;
    self.zf_lastOffsetY = offsetY;
    if (self.zf_stopPlay) return;
    
    UIView *playerView;
    if (self.zf_containerType == ZFPlayerContainerTypeCell) {
        // Avoid being paused the first time you play it.
        if (self.contentOffset.y < 0) return;
        if (!self.zf_playingIndexPath) return;
        
        UIView *cell = [self zf_getCellForIndexPath:self.zf_playingIndexPath];
        if (!cell) {
            if (self.zf_playerDidDisappearInScrollView) self.zf_playerDidDisappearInScrollView(self.zf_playingIndexPath);
            return;
        }
        playerView = [cell viewWithTag:self.zf_containerViewTag];
    } else if (self.zf_containerType == ZFPlayerContainerTypeView) {
        if (!self.zf_containerView) return;
        playerView = self.zf_containerView;
    }
    
    CGRect rect1 = [playerView convertRect:playerView.frame toView:self];
    CGRect rect = [self convertRect:rect1 toView:self.superview];
    /// playerView top to scrollView top space.
    CGFloat topSpacing = CGRectGetMinY(rect) - CGRectGetMinY(self.frame) - CGRectGetMinY(playerView.frame);
    /// playerView bottom to scrollView bottom space.
    CGFloat bottomSpacing = CGRectGetMaxY(self.frame) - CGRectGetMaxY(rect) + CGRectGetMinY(playerView.frame);
    /// The height of the content area.
    CGFloat contentInsetHeight = CGRectGetMaxY(self.frame) - CGRectGetMinY(self.frame);
    
    CGFloat playerDisapperaPercent = 0;
    CGFloat playerApperaPercent = 0;
    
    if (self.zf_scrollDirection == ZFPlayerScrollDirectionUp) { /// Scroll up
        /// Player is disappearing.
        if (topSpacing <= 0 && CGRectGetHeight(rect) != 0) {
            playerDisapperaPercent = -topSpacing/CGRectGetHeight(rect);
            if (playerDisapperaPercent > 1.0) playerDisapperaPercent = 1.0;
            if (self.zf_playerDisappearingInScrollView) self.zf_playerDisappearingInScrollView(self.zf_playingIndexPath, playerDisapperaPercent);
        }
        
        /// Top area
        if (topSpacing <= 0 && topSpacing > -CGRectGetHeight(rect)/2) {
            /// When the player will disappear.
            if (self.zf_playerWillDisappearInScrollView) self.zf_playerWillDisappearInScrollView(self.zf_playingIndexPath);
        } else if (topSpacing <= -CGRectGetHeight(rect)) {
            /// When the player did disappeared.
            if (self.zf_playerDidDisappearInScrollView) self.zf_playerDidDisappearInScrollView(self.zf_playingIndexPath);
        } else if (topSpacing > 0 && topSpacing <= contentInsetHeight) {
            /// Player is appearing.
            if (CGRectGetHeight(rect) != 0) {
                playerApperaPercent = -(topSpacing-contentInsetHeight)/CGRectGetHeight(rect);
                if (playerApperaPercent > 1.0) playerApperaPercent = 1.0;
                if (self.zf_playerAppearingInScrollView) self.zf_playerAppearingInScrollView(self.zf_playingIndexPath, playerApperaPercent);
            }
            /// In visable area
            if (topSpacing <= contentInsetHeight && topSpacing > contentInsetHeight-CGRectGetHeight(rect)/2) {
                /// When the player will appear.
                if (self.zf_playerWillAppearInScrollView) self.zf_playerWillAppearInScrollView(self.zf_playingIndexPath);
            } else {
                /// When the player did appeared.
                if (self.zf_playerDidAppearInScrollView) self.zf_playerDidAppearInScrollView(self.zf_playingIndexPath);
            }
        }
        
    } else if (self.zf_scrollDirection == ZFPlayerScrollDirectionDown) { /// Scroll Down
        /// Player is disappearing.
        if (bottomSpacing <= 0 && CGRectGetHeight(rect) != 0) {
            playerDisapperaPercent = -bottomSpacing/CGRectGetHeight(rect);
            if (playerDisapperaPercent > 1.0) playerDisapperaPercent = 1.0;
            if (self.zf_playerDisappearingInScrollView) self.zf_playerDisappearingInScrollView(self.zf_playingIndexPath, playerDisapperaPercent);
        }
        
        /// Bottom area
        if (bottomSpacing <= 0 && bottomSpacing > -CGRectGetHeight(rect)/2) {
            /// When the player will disappear.
            if (self.zf_playerWillDisappearInScrollView) self.zf_playerWillDisappearInScrollView(self.zf_playingIndexPath);
        } else if (bottomSpacing <= -CGRectGetHeight(rect)) {
            /// When the player did disappeared.
            if (self.zf_playerDidDisappearInScrollView) self.zf_playerDidDisappearInScrollView(self.zf_playingIndexPath);
        } else if (bottomSpacing > 0 && bottomSpacing <= contentInsetHeight) {
            /// Player is appearing.
            if (CGRectGetHeight(rect) != 0) {
                playerApperaPercent = -(bottomSpacing-contentInsetHeight)/CGRectGetHeight(rect);
                if (playerApperaPercent > 1.0) playerApperaPercent = 1.0;
                if (self.zf_playerAppearingInScrollView) self.zf_playerAppearingInScrollView(self.zf_playingIndexPath, playerApperaPercent);
            }
            /// In visable area
            if (bottomSpacing <= contentInsetHeight && bottomSpacing > contentInsetHeight-CGRectGetHeight(rect)/2) {
                /// When the player will appear.
                if (self.zf_playerWillAppearInScrollView) self.zf_playerWillAppearInScrollView(self.zf_playingIndexPath);
            } else {
                /// When the player did appeared.
                if (self.zf_playerDidAppearInScrollView) self.zf_playerDidAppearInScrollView(self.zf_playingIndexPath);
            }
        }
    }
}

/**
 The percentage of scrolling processed in horizontal scrolling.
 */
- (void)_scrollViewScrollingDirectionHorizontal {
    CGFloat offsetX = self.contentOffset.x;
    self.zf_scrollDirection = (offsetX - self.zf_lastOffsetX > 0) ? ZFPlayerScrollDirectionLeft : ZFPlayerScrollDirectionRight;
    self.zf_lastOffsetX = offsetX;
    if (self.zf_stopPlay) return;
    
    UIView *playerView;
    if (self.zf_containerType == ZFPlayerContainerTypeCell) {
        // Avoid being paused the first time you play it.
        if (self.contentOffset.x < 0) return;
        if (!self.zf_playingIndexPath) return;
        
        UIView *cell = [self zf_getCellForIndexPath:self.zf_playingIndexPath];
        if (!cell) {
            if (self.zf_playerDidDisappearInScrollView) self.zf_playerDidDisappearInScrollView(self.zf_playingIndexPath);
            return;
        }
       playerView = [cell viewWithTag:self.zf_containerViewTag];
    } else if (self.zf_containerType == ZFPlayerContainerTypeView) {
        if (!self.zf_containerView) return;
        playerView = self.zf_containerView;
    }
    
    CGRect rect1 = [playerView convertRect:playerView.frame toView:self];
    CGRect rect = [self convertRect:rect1 toView:self.superview];
    /// playerView left to scrollView left space.
    CGFloat leftSpacing = CGRectGetMinX(rect) - CGRectGetMinX(self.frame) - CGRectGetMinX(playerView.frame);
    /// playerView bottom to scrollView right space.
    CGFloat rightSpacing = CGRectGetMaxX(self.frame) - CGRectGetMaxX(rect) + CGRectGetMinX(playerView.frame);
    /// The height of the content area.
    CGFloat contentInsetWidth = CGRectGetMaxX(self.frame) - CGRectGetMinX(self.frame);
    
    CGFloat playerDisapperaPercent = 0;
    CGFloat playerApperaPercent = 0;
    
    if (self.zf_scrollDirection == ZFPlayerScrollDirectionLeft) { /// Scroll left
        /// Player is disappearing.
        if (leftSpacing <= 0 && CGRectGetWidth(rect) != 0) {
            playerDisapperaPercent = -leftSpacing/CGRectGetWidth(rect);
            if (playerDisapperaPercent > 1.0) playerDisapperaPercent = 1.0;
            if (self.zf_playerDisappearingInScrollView) self.zf_playerDisappearingInScrollView(self.zf_playingIndexPath, playerDisapperaPercent);
        }
        
        /// Top area
        if (leftSpacing <= 0 && leftSpacing > -CGRectGetWidth(rect)/2) {
            /// When the player will disappear.
            if (self.zf_playerWillDisappearInScrollView) self.zf_playerWillDisappearInScrollView(self.zf_playingIndexPath);
        } else if (leftSpacing <= -CGRectGetWidth(rect)) {
            /// When the player did disappeared.
            if (self.zf_playerDidDisappearInScrollView) self.zf_playerDidDisappearInScrollView(self.zf_playingIndexPath);
        } else if (leftSpacing > 0 && leftSpacing <= contentInsetWidth) {
            /// Player is appearing.
            if (CGRectGetWidth(rect) != 0) {
                playerApperaPercent = -(leftSpacing-contentInsetWidth)/CGRectGetWidth(rect);
                if (playerApperaPercent > 1.0) playerApperaPercent = 1.0;
                if (self.zf_playerAppearingInScrollView) self.zf_playerAppearingInScrollView(self.zf_playingIndexPath, playerApperaPercent);
            }
            /// In visable area
            if (leftSpacing <= contentInsetWidth && leftSpacing > contentInsetWidth-CGRectGetWidth(rect)/2) {
                /// When the player will appear.
                if (self.zf_playerWillAppearInScrollView) self.zf_playerWillAppearInScrollView(self.zf_playingIndexPath);
            } else {
                /// When the player did appeared.
                if (self.zf_playerDidAppearInScrollView) self.zf_playerDidAppearInScrollView(self.zf_playingIndexPath);
            }
        }
        
    } else if (self.zf_scrollDirection == ZFPlayerScrollDirectionRight) { /// Scroll right
        /// Player is disappearing.
        if (rightSpacing <= 0 && CGRectGetWidth(rect) != 0) {
            playerDisapperaPercent = -rightSpacing/CGRectGetWidth(rect);
            if (playerDisapperaPercent > 1.0) playerDisapperaPercent = 1.0;
            if (self.zf_playerDisappearingInScrollView) self.zf_playerDisappearingInScrollView(self.zf_playingIndexPath, playerDisapperaPercent);
        }
        
        /// Bottom area
        if (rightSpacing <= 0 && rightSpacing > -CGRectGetWidth(rect)/2) {
            /// When the player will disappear.
            if (self.zf_playerWillDisappearInScrollView) self.zf_playerWillDisappearInScrollView(self.zf_playingIndexPath);
        } else if (rightSpacing <= -CGRectGetWidth(rect)) {
            /// When the player did disappeared.
            if (self.zf_playerDidDisappearInScrollView) self.zf_playerDidDisappearInScrollView(self.zf_playingIndexPath);
        } else if (rightSpacing > 0 && rightSpacing <= contentInsetWidth) {
            /// Player is appearing.
            if (CGRectGetWidth(rect) != 0) {
                playerApperaPercent = -(rightSpacing-contentInsetWidth)/CGRectGetWidth(rect);
                if (playerApperaPercent > 1.0) playerApperaPercent = 1.0;
                if (self.zf_playerAppearingInScrollView) self.zf_playerAppearingInScrollView(self.zf_playingIndexPath, playerApperaPercent);
            }
            /// In visable area
            if (rightSpacing <= contentInsetWidth && rightSpacing > contentInsetWidth-CGRectGetWidth(rect)/2) {
                /// When the player will appear.
                if (self.zf_playerWillAppearInScrollView) self.zf_playerWillAppearInScrollView(self.zf_playingIndexPath);
            } else {
                /// When the player did appeared.
                if (self.zf_playerDidAppearInScrollView) self.zf_playerDidAppearInScrollView(self.zf_playingIndexPath);
            }
        }
    }
}

/**
 Find the playing cell while the scrollDirection is vertical.
 */
- (void)_findCorrectCellWhenScrollViewDirectionVertical:(void (^ __nullable)(NSIndexPath *indexPath))handler {
    if (!self.zf_shouldAutoPlay) return;
    if (self.zf_containerType == ZFPlayerContainerTypeView) return;

    if (!self.zf_stopWhileNotVisible) {
        /// If you have a cell that is playing, stop the traversal.
        if (self.zf_playingIndexPath) {
            NSIndexPath *finalIndexPath = self.zf_playingIndexPath;
            if (self.zf_scrollViewDidScrollCallback) self.zf_scrollViewDidScrollCallback(finalIndexPath);
            if (handler) handler(finalIndexPath);
            self.zf_shouldPlayIndexPath = finalIndexPath;
            return;
        }
    }
    NSArray *visiableCells = nil;
    NSIndexPath *indexPath = nil;
    if ([self _isTableView]) {
        UITableView *tableView = (UITableView *)self;
        visiableCells = [tableView visibleCells];
        // First visible cell indexPath
        indexPath = tableView.indexPathsForVisibleRows.firstObject;
        if ((self.contentOffset.y <= 0 || self.contentOffset.y + self.frame.size.height >= self.contentSize.height) && (!self.zf_playingIndexPath || [indexPath compare:self.zf_playingIndexPath] == NSOrderedSame)) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            UIView *playerView = [cell viewWithTag:self.zf_containerViewTag];
            if (playerView && !playerView.hidden && playerView.alpha > 0.01) {
                if (self.zf_scrollViewDidScrollCallback) self.zf_scrollViewDidScrollCallback(indexPath);
                if (handler) handler(indexPath);
                self.zf_shouldPlayIndexPath = indexPath;
                return;
            }
        }
    } else if ([self _isCollectionView]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        visiableCells = [collectionView visibleCells];
        visiableCells = [visiableCells sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSIndexPath *path1 = (NSIndexPath *)[collectionView indexPathForCell:obj1];
            NSIndexPath *path2 = (NSIndexPath *)[collectionView indexPathForCell:obj2];
            return [path1 compare:path2];
        }];
        
        CGPoint center = CGPointMake(collectionView.frame.size.width / 2, collectionView.contentOffset.y + (collectionView.frame.size.height / 2));
        indexPath = [collectionView indexPathForItemAtPoint:center];
        if ((self.contentOffset.y <= 0 || self.contentOffset.y + self.frame.size.height >= self.contentSize.height) && (!self.zf_playingIndexPath || [indexPath compare:self.zf_playingIndexPath] == NSOrderedSame)) {
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            UIView *playerView = [cell viewWithTag:self.zf_containerViewTag];
            if (playerView && !playerView.hidden && playerView.alpha > 0.01) {
                if (self.zf_scrollViewDidScrollCallback) self.zf_scrollViewDidScrollCallback(indexPath);
                if (handler) handler(indexPath);
                self.zf_shouldPlayIndexPath = indexPath;
                return;
            }
        }
    }
    
    NSArray *cells = nil;
    if (self.zf_scrollDirection == ZFPlayerScrollDirectionUp) {
        cells = visiableCells;
    } else {
        cells = [visiableCells reverseObjectEnumerator].allObjects;
    }
    
    /// Mid line.
    CGFloat scrollViewMidY = CGRectGetHeight(self.frame)/2;
    /// The final playing indexPath.
    __block NSIndexPath *finalIndexPath = nil;
    /// The final distance from the center line.
    __block CGFloat finalSpace = 0;
    @zf_weakify(self)
    [cells enumerateObjectsUsingBlock:^(UIView *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        @zf_strongify(self)
        UIView *playerView = [cell viewWithTag:self.zf_containerViewTag];
        if (!playerView || playerView.hidden || playerView.alpha <= 0.01) return;
        CGRect rect1 = [playerView convertRect:playerView.frame toView:self];
        CGRect rect = [self convertRect:rect1 toView:self.superview];
        /// playerView top to scrollView top space.
        CGFloat topSpacing = CGRectGetMinY(rect) - CGRectGetMinY(self.frame) - CGRectGetMinY(playerView.frame);
        /// playerView bottom to scrollView bottom space.
        CGFloat bottomSpacing = CGRectGetMaxY(self.frame) - CGRectGetMaxY(rect) + CGRectGetMinY(playerView.frame);
        CGFloat centerSpacing = ABS(scrollViewMidY - CGRectGetMidY(rect));
        NSIndexPath *indexPath = [self zf_getIndexPathForCell:cell];
        
        /// Play when the video playback section is visible.
        if ((topSpacing >= -(1 - self.zf_playerApperaPercent) * CGRectGetHeight(rect)) && (bottomSpacing >= -(1 - self.zf_playerApperaPercent) * CGRectGetHeight(rect))) {
            if (!finalIndexPath || centerSpacing < finalSpace) {
                finalIndexPath = indexPath;
                finalSpace = centerSpacing;
            }
        }
    }];
    /// if find the playing indexPath.
    if (finalIndexPath) {
        if (self.zf_scrollViewDidScrollCallback) self.zf_scrollViewDidScrollCallback(indexPath);
        if (handler) handler(finalIndexPath);
    }
    self.zf_shouldPlayIndexPath = finalIndexPath;
}

/**
 Find the playing cell while the scrollDirection is horizontal.
 */
- (void)_findCorrectCellWhenScrollViewDirectionHorizontal:(void (^ __nullable)(NSIndexPath *indexPath))handler {
    if (!self.zf_shouldAutoPlay) return;
    if (self.zf_containerType == ZFPlayerContainerTypeView) return;
    if (!self.zf_stopWhileNotVisible) {
        /// If you have a cell that is playing, stop the traversal.
        if (self.zf_playingIndexPath) {
            NSIndexPath *finalIndexPath = self.zf_playingIndexPath;
            if (self.zf_scrollViewDidScrollCallback) self.zf_scrollViewDidScrollCallback(finalIndexPath);
            if (handler) handler(finalIndexPath);
            self.zf_shouldPlayIndexPath = finalIndexPath;
            return;
        }
    }
    
    NSArray *visiableCells = nil;
    NSIndexPath *indexPath = nil;
    if ([self _isTableView]) {
        UITableView *tableView = (UITableView *)self;
        visiableCells = [tableView visibleCells];
        // First visible cell indexPath
        indexPath = tableView.indexPathsForVisibleRows.firstObject;
        if ((self.contentOffset.x <= 0 || self.contentOffset.x + self.frame.size.width >= self.contentSize.width) && (!self.zf_playingIndexPath || [indexPath compare:self.zf_playingIndexPath] == NSOrderedSame)) {
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            UIView *playerView = [cell viewWithTag:self.zf_containerViewTag];
            if (playerView && !playerView.hidden && playerView.alpha > 0.01) {
                if (self.zf_scrollViewDidScrollCallback) self.zf_scrollViewDidScrollCallback(indexPath);
                if (handler) handler(indexPath);
                self.zf_shouldPlayIndexPath = indexPath;
                return;
            }
        }
    } else if ([self _isCollectionView]) {
        UICollectionView *collectionView = (UICollectionView *)self;
        visiableCells = [collectionView visibleCells];
        visiableCells = [visiableCells sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSIndexPath *path1 = (NSIndexPath *)[collectionView indexPathForCell:obj1];
            NSIndexPath *path2 = (NSIndexPath *)[collectionView indexPathForCell:obj2];
            return [path1 compare:path2];
        }];
        
        CGPoint center = CGPointMake(collectionView.contentOffset.x + (collectionView.frame.size.width / 2), collectionView.frame.size.height / 2);
        indexPath = [collectionView indexPathForItemAtPoint:center];
        if ((self.contentOffset.x <= 0 || self.contentOffset.x + self.frame.size.width >= self.contentSize.width) && (!self.zf_playingIndexPath || [indexPath compare:self.zf_playingIndexPath] == NSOrderedSame)) {
            UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
            UIView *playerView = [cell viewWithTag:self.zf_containerViewTag];
            if (playerView && !playerView.hidden && playerView.alpha > 0.01) {
                if (self.zf_scrollViewDidScrollCallback) self.zf_scrollViewDidScrollCallback(indexPath);
                if (handler) handler(indexPath);
                self.zf_shouldPlayIndexPath = indexPath;
                return;
            }
        }
    }
    
    NSArray *cells = nil;
    if (self.zf_scrollDirection == ZFPlayerScrollDirectionUp) {
        cells = visiableCells;
    } else {
        cells = [visiableCells reverseObjectEnumerator].allObjects;
    }
    
    /// Mid line.
    CGFloat scrollViewMidX = CGRectGetWidth(self.frame)/2;
    /// The final playing indexPath.
    __block NSIndexPath *finalIndexPath = nil;
    /// The final distance from the center line.
    __block CGFloat finalSpace = 0;
    @zf_weakify(self)
    [cells enumerateObjectsUsingBlock:^(UIView *cell, NSUInteger idx, BOOL * _Nonnull stop) {
        @zf_strongify(self)
        UIView *playerView = [cell viewWithTag:self.zf_containerViewTag];
        if (!playerView || playerView.hidden || playerView.alpha <= 0.01) return;
        CGRect rect1 = [playerView convertRect:playerView.frame toView:self];
        CGRect rect = [self convertRect:rect1 toView:self.superview];
        /// playerView left to scrollView top space.
        CGFloat leftSpacing = CGRectGetMinX(rect) - CGRectGetMinX(self.frame) - CGRectGetMinX(playerView.frame);
        /// playerView right to scrollView top space.
        CGFloat rightSpacing = CGRectGetMaxX(self.frame) - CGRectGetMaxX(rect) + CGRectGetMinX(playerView.frame);
        CGFloat centerSpacing = ABS(scrollViewMidX - CGRectGetMidX(rect));
        NSIndexPath *indexPath = [self zf_getIndexPathForCell:cell];
        
        /// Play when the video playback section is visible.
        if ((leftSpacing >= -(1 - self.zf_playerApperaPercent) * CGRectGetWidth(rect)) && (rightSpacing >= -(1 - self.zf_playerApperaPercent) * CGRectGetWidth(rect))) {
            if (!finalIndexPath || centerSpacing < finalSpace) {
                finalIndexPath = indexPath;
                finalSpace = centerSpacing;
            }
        }
    }];
    /// if find the playing indexPath.
    if (finalIndexPath) {
        if (self.zf_scrollViewDidScrollCallback) self.zf_scrollViewDidScrollCallback(indexPath);
        if (handler) handler(finalIndexPath);
        self.zf_shouldPlayIndexPath = finalIndexPath;
    }
}

- (BOOL)_isTableView {
    return [self isKindOfClass:[UITableView class]];
}

- (BOOL)_isCollectionView {
    return [self isKindOfClass:[UICollectionView class]];
}

#pragma mark - getter

- (ZFPlayerScrollDirection)zf_scrollDirection {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (ZFPlayerScrollViewDirection)zf_scrollViewDirection {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (CGFloat)zf_lastOffsetY {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (CGFloat)zf_lastOffsetX {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

#pragma mark - setter

- (void)setZf_scrollDirection:(ZFPlayerScrollDirection)zf_scrollDirection {
    objc_setAssociatedObject(self, @selector(zf_scrollDirection), @(zf_scrollDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_scrollViewDirection:(ZFPlayerScrollViewDirection)zf_scrollViewDirection {
    objc_setAssociatedObject(self, @selector(zf_scrollViewDirection), @(zf_scrollViewDirection), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_lastOffsetY:(CGFloat)zf_lastOffsetY {
    objc_setAssociatedObject(self, @selector(zf_lastOffsetY), @(zf_lastOffsetY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_lastOffsetX:(CGFloat)zf_lastOffsetX {
    objc_setAssociatedObject(self, @selector(zf_lastOffsetX), @(zf_lastOffsetX), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIScrollView (ZFPlayerCannotCalled)

- (void)zf_filterShouldPlayCellWhileScrolling:(void (^ __nullable)(NSIndexPath *indexPath))handler {
    if (self.zf_scrollViewDirection == ZFPlayerScrollViewDirectionVertical) {
        [self _findCorrectCellWhenScrollViewDirectionVertical:handler];
    } else {
        [self _findCorrectCellWhenScrollViewDirectionHorizontal:handler];
    }
}

- (void)zf_filterShouldPlayCellWhileScrolled:(void (^ __nullable)(NSIndexPath *indexPath))handler {
    if (!self.zf_shouldAutoPlay) return;
    @zf_weakify(self)
    [self zf_filterShouldPlayCellWhileScrolling:^(NSIndexPath *indexPath) {
        @zf_strongify(self)
        /// 如果当前控制器已经消失，直接return
        if (self.zf_viewControllerDisappear) return;
        if ([ZFReachabilityManager sharedManager].isReachableViaWWAN && !self.zf_WWANAutoPlay) {
            /// 移动网络
            self.zf_shouldPlayIndexPath = indexPath;
            return;
        }
        if (handler) handler(indexPath);
        self.zf_playingIndexPath = indexPath;
    }];
}

#pragma mark - getter

- (void (^)(NSIndexPath * _Nonnull, CGFloat))zf_playerDisappearingInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull, CGFloat))zf_playerAppearingInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerDidAppearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerWillDisappearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerWillAppearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerDidDisappearInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidEndScrollingCallback {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidScrollCallback {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_playerShouldPlayInScrollView {
    return objc_getAssociatedObject(self, _cmd);
}

- (CGFloat)zf_playerApperaPercent {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (CGFloat)zf_playerDisapperaPercent {
    return [objc_getAssociatedObject(self, _cmd) floatValue];
}

- (BOOL)zf_viewControllerDisappear {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)zf_stopPlay {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.zf_stopPlay = YES;
    return YES;
}

- (BOOL)zf_stopWhileNotVisible {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (NSIndexPath *)zf_playingIndexPath {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSIndexPath *)zf_shouldPlayIndexPath {
    return objc_getAssociatedObject(self, _cmd);
}

- (NSInteger)zf_containerViewTag {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (BOOL)zf_isWWANAutoPlay {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (BOOL)zf_shouldAutoPlay {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) return number.boolValue;
    self.zf_shouldAutoPlay = YES;
    return YES;
}

- (ZFPlayerContainerType)zf_containerType {
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (UIView *)zf_containerView {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - setter

- (void)setZf_playerDisappearingInScrollView:(void (^)(NSIndexPath * _Nonnull, CGFloat))zf_playerDisappearingInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerDisappearingInScrollView), zf_playerDisappearingInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerAppearingInScrollView:(void (^)(NSIndexPath * _Nonnull, CGFloat))zf_playerAppearingInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerAppearingInScrollView), zf_playerAppearingInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerDidAppearInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerDidAppearInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerDidAppearInScrollView), zf_playerDidAppearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerWillDisappearInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerWillDisappearInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerWillDisappearInScrollView), zf_playerWillDisappearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerWillAppearInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerWillAppearInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerWillAppearInScrollView), zf_playerWillAppearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerDidDisappearInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerDidDisappearInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerDidDisappearInScrollView), zf_playerDidDisappearInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_scrollViewDidEndScrollingCallback:(void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidEndScrollingCallback {
    objc_setAssociatedObject(self, @selector(zf_scrollViewDidEndScrollingCallback), zf_scrollViewDidEndScrollingCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_scrollViewDidScrollCallback:(void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidScrollCallback {
    objc_setAssociatedObject(self, @selector(zf_scrollViewDidScrollCallback), zf_scrollViewDidScrollCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerShouldPlayInScrollView:(void (^)(NSIndexPath * _Nonnull))zf_playerShouldPlayInScrollView {
    objc_setAssociatedObject(self, @selector(zf_playerShouldPlayInScrollView), zf_playerShouldPlayInScrollView, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerApperaPercent:(CGFloat)zf_playerApperaPercent {
    objc_setAssociatedObject(self, @selector(zf_playerApperaPercent), @(zf_playerApperaPercent), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_playerDisapperaPercent:(CGFloat)zf_playerDisapperaPercent {
    objc_setAssociatedObject(self, @selector(zf_playerDisapperaPercent), @(zf_playerDisapperaPercent), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_viewControllerDisappear:(BOOL)zf_viewControllerDisappear {
    objc_setAssociatedObject(self, @selector(zf_viewControllerDisappear), @(zf_viewControllerDisappear), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_stopPlay:(BOOL)zf_stopPlay {
    objc_setAssociatedObject(self, @selector(zf_stopPlay), @(zf_stopPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_stopWhileNotVisible:(BOOL)zf_stopWhileNotVisible {
    objc_setAssociatedObject(self, @selector(zf_stopWhileNotVisible), @(zf_stopWhileNotVisible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_playingIndexPath:(NSIndexPath *)zf_playingIndexPath {
    objc_setAssociatedObject(self, @selector(zf_playingIndexPath), zf_playingIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (zf_playingIndexPath && [zf_playingIndexPath compare:self.zf_shouldPlayIndexPath] != NSOrderedSame) {
        self.zf_shouldPlayIndexPath = zf_playingIndexPath;
    }
}

- (void)setZf_shouldPlayIndexPath:(NSIndexPath *)zf_shouldPlayIndexPath {
    if (self.zf_playerShouldPlayInScrollView) self.zf_playerShouldPlayInScrollView(zf_shouldPlayIndexPath);
    if (self.zf_shouldPlayIndexPathCallback) self.zf_shouldPlayIndexPathCallback(zf_shouldPlayIndexPath);
    objc_setAssociatedObject(self, @selector(zf_shouldPlayIndexPath), zf_shouldPlayIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_containerViewTag:(NSInteger)zf_containerViewTag {
    objc_setAssociatedObject(self, @selector(zf_containerViewTag), @(zf_containerViewTag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_containerType:(ZFPlayerContainerType)zf_containerType {
    objc_setAssociatedObject(self, @selector(zf_containerType), @(zf_containerType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_containerView:(UIView *)zf_containerView {
    objc_setAssociatedObject(self, @selector(zf_containerView), zf_containerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_shouldAutoPlay:(BOOL)zf_shouldAutoPlay {
    objc_setAssociatedObject(self, @selector(zf_shouldAutoPlay), @(zf_shouldAutoPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZf_WWANAutoPlay:(BOOL)zf_WWANAutoPlay {
    objc_setAssociatedObject(self, @selector(zf_isWWANAutoPlay), @(zf_WWANAutoPlay), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation UIScrollView (ZFPlayerDeprecated)

#pragma mark - getter

- (void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidStopScrollCallback {
    return objc_getAssociatedObject(self, _cmd);
}

- (void (^)(NSIndexPath * _Nonnull))zf_shouldPlayIndexPathCallback {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - setter

- (void)setZf_scrollViewDidStopScrollCallback:(void (^)(NSIndexPath * _Nonnull))zf_scrollViewDidStopScrollCallback {
    objc_setAssociatedObject(self, @selector(zf_scrollViewDidStopScrollCallback), zf_scrollViewDidStopScrollCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)setZf_shouldPlayIndexPathCallback:(void (^)(NSIndexPath * _Nonnull))zf_shouldPlayIndexPathCallback {
    objc_setAssociatedObject(self, @selector(zf_shouldPlayIndexPathCallback), zf_shouldPlayIndexPathCallback, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - method

- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath completionHandler:(void (^ __nullable)(void))completionHandler {
    [self zf_scrollToRowAtIndexPath:indexPath animated:YES completionHandler:completionHandler];
}

- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated completionHandler:(void (^ __nullable)(void))completionHandler {
    [self zf_scrollToRowAtIndexPath:indexPath animateWithDuration:animated ? 0.4 : 0.0 completionHandler:completionHandler];
}

/// Scroll to indexPath with animations duration.
- (void)zf_scrollToRowAtIndexPath:(NSIndexPath *)indexPath animateWithDuration:(NSTimeInterval)duration completionHandler:(void (^ __nullable)(void))completionHandler {
    [self zf_scrollToRowAtIndexPath:indexPath atScrollPosition:ZFPlayerScrollViewScrollPositionTop animateDuration:duration completionHandler:completionHandler];
}

@end

#pragma clang diagnostic pop
