//
//  NSWindow+endEditing.m
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 10/17/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSWindow+endEditing.h"

// A graceful solution by https://red-sweater.com/blog/229/stay-responsive

@implementation NSWindow(endEditing)

- (void)endEditing {
    // Save the current first responder, respecting the fact
    // that it might conceptually be the delegate of the
    // field editor that is "first responder."
    id oldFirstResponder = [self firstResponder];
    if ((oldFirstResponder != nil) &&
        [oldFirstResponder isKindOfClass:[NSTextView class]] &&
        [(NSTextView*)oldFirstResponder isFieldEditor])
    {
        // A field editor's delegate is the view we're editing
        oldFirstResponder = [oldFirstResponder delegate];
        if ([oldFirstResponder isKindOfClass:[NSResponder class]] == NO)
        {
            // Eh ... we'd better back off if
            // this thing isn't a responder at all
            oldFirstResponder = nil;
        }
    }

    // Gracefully end all editing in our window (from Erik Buck).
    // This will cause the user's changes to be committed.
    if([self makeFirstResponder:self])
    {
        // All editing is now ended and delegate messages sent etc.
    }
    else
    {
        // For some reason the text object being edited will
        // not resign first responder status so force an
        /// end to editing anyway
        [self endEditingFor:nil];
    }

    // If we had a first responder before, restore it
    if (oldFirstResponder != nil)
    {
        [self makeFirstResponder:oldFirstResponder];
    }
}

@end
