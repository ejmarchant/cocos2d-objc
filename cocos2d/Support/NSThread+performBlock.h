/* cocos2d for iPhone
 *
 * http://www.cocos2d-iphone.org
 *
 *
 * Idea taken from: http://stackoverflow.com/a/3940757
 *
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSThread (sendBlockToBackground)
/* performs a block on the thread. It won't wait until it is done. */
- (void) performBlock:(void (^)(void))block;

/* performs a block on the thread. */
- (void) performBlock:(void (^)(void))block waitUntilDone:(BOOL)wait;

/* performs a block on the thread. */
- (void) performBlock:(void (^)(id param))block withObject:(nullable id)object waitUntilDone:(BOOL)wait;

@end

NS_ASSUME_NONNULL_END
