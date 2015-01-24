//
//  CGGeometry+Pull.h
//  Pull
//
//  Created by Development on 1/18/15.
//  Copyright (c) 2015 Pull LLC. All rights reserved.
//

#ifndef Pull_CGGeometry_Pull_h
#define Pull_CGGeometry_Pull_h

/**
 * Calculate the vector-scalar product A*b
 */
static inline CGPoint CGPointScale(CGPoint A, double b) {
    return CGPointMake(A.x*b, A.y*b);
}

/**
 * Calculate the vector-vector sum a+b
 */
static inline CGPoint CGPointAdd(CGPoint a, CGPoint b) {
    return CGPointMake(a.x + b.x, a.y + b.y);
}

/**
 * Calculate the vector-vector difference a-b
 */
static inline CGPoint CGPointSubtract(CGPoint a, CGPoint b) {
    return CGPointMake(a.x - b.x, a.y - b.y);
}

/**
 * Calculate the cross product for two 2D vectors by treating them as 3D
 * vectors with zero for the third component. As the direction of the
 * resulting vector is always directly up the z-axis, this returns a scalar
 * equal to |a|*|b|*sin(alpha) where alpha is the angle in the plane between
 * a and b.
 */
static inline double CGPointCross(CGPoint a, CGPoint b) {
    return a.x*b.y - b.x*a.y;
}

/**
 * Calculate the dot-product of two 2D vectors a dot b
 */
static inline double CGPointDot(CGPoint a, CGPoint b) {
    return a.x*b.x + a.y*b.y;
}

/**
 * Calculate the magnitude of a 2D vector
 */
static inline double CGPointMagnitude(CGPoint pt) {
    return sqrt(CGPointDot(pt, pt));
}

/**
 * Normalize a 2D vector
 */
static inline CGPoint CGPointNormalize(CGPoint pt) {
    return CGPointScale(pt, 1.0 / CGPointMagnitude(pt));
}

#endif
