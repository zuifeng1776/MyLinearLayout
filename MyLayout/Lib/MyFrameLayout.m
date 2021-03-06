//
//  MyFrameLayout.m
//  MyLayout
//
//  Created by oybq on 15/6/14.
//  Copyright (c) 2015年 YoungSoft. All rights reserved.
//

#import "MyFrameLayout.h"
#import "MyLayoutInner.h"
#import <objc/runtime.h>


@implementation UIView(MyFrameLayoutExt)


-(MyMarginGravity)marginGravity
{
    return self.myCurrentSizeClass.marginGravity;
}


-(void)setMarginGravity:(MyMarginGravity)marginGravity
{
    if (self.myCurrentSizeClass.marginGravity != marginGravity)
    {
        self.myCurrentSizeClass.marginGravity = marginGravity;
        if (self.superview != nil)
            [self.superview setNeedsLayout];
    }
}

@end

IB_DESIGNABLE
@implementation MyFrameLayout

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


-(void)calcSubView:(UIView*)sbv pRect:(CGRect*)pRect inSize:(CGSize)selfSize
{
    
    MyMarginGravity gravity = sbv.marginGravity;
    MyMarginGravity vert = gravity & MyMarginGravity_Horz_Mask;
    MyMarginGravity horz = gravity & MyMarginGravity_Vert_Mask;
    
     
    //优先用设定的宽度尺寸。
    if (sbv.widthDime.dimeNumVal != nil)
        pRect->size.width = sbv.widthDime.measure;
    
    if (sbv.heightDime.dimeNumVal != nil)
        pRect->size.height = sbv.heightDime.measure;
    
    if (sbv.widthDime.dimeRelaVal != nil && sbv.widthDime.dimeRelaVal.view != sbv)
    {
        if (sbv.widthDime.dimeRelaVal.view == self)
            pRect->size.width = (selfSize.width - self.leftPadding - self.rightPadding) * sbv.widthDime.mutilVal + sbv.widthDime.addVal;
        else
            pRect->size.width = sbv.widthDime.dimeRelaVal.view.absPos.width * sbv.widthDime.mutilVal + sbv.widthDime.addVal;
    }
    
    if (sbv.heightDime.dimeRelaVal != nil && sbv.heightDime.dimeRelaVal.view != sbv)
    {
        if (sbv.heightDime.dimeRelaVal.view == self)
            pRect->size.height = (selfSize.height - self.topPadding - self.bottomPadding) * sbv.heightDime.mutilVal + sbv.heightDime.addVal;
        else
            pRect->size.height = sbv.heightDime.dimeRelaVal.view.absPos.height * sbv.heightDime.mutilVal + sbv.heightDime.addVal;
        
    }
    
    pRect->size.width = [self validMeasure:sbv.widthDime sbv:sbv calcSize:pRect->size.width sbvSize:pRect->size selfLayoutSize:selfSize];
    
   
    //特殊处理如果设置了左右边距则确定了视图的宽度
    if (sbv.leftPos.posVal != nil && sbv.rightPos.posVal != nil)
        horz = MyMarginGravity_Horz_Fill;
    
    [self horzGravity:horz selfSize:selfSize sbv:sbv rect:pRect];
   
    
    
    if (sbv.isFlexedHeight)
    {
        pRect->size.height = [self heightFromFlexedHeightView:sbv inWidth:pRect->size.width];

    }
    
     pRect->size.height = [self validMeasure:sbv.heightDime sbv:sbv calcSize:pRect->size.height sbvSize:pRect->size selfLayoutSize:selfSize];
    
    if (sbv.topPos.posVal != nil && sbv.bottomPos.posVal != nil)
        vert = MyMarginGravity_Vert_Fill;
    
    [self vertGravity:vert selfSize:selfSize sbv:sbv rect:pRect];
    
    
    if (sbv.widthDime.dimeRelaVal != nil && sbv.widthDime.dimeRelaVal.view == sbv && sbv.widthDime.dimeRelaVal.dime == MyMarginGravity_Vert_Fill)
    {
        
        pRect->size.width = [self validMeasure:sbv.widthDime sbv:sbv calcSize:pRect->size.height * sbv.widthDime.mutilVal + sbv.widthDime.addVal sbvSize:pRect->size selfLayoutSize:selfSize];
        
    }
    
    if (sbv.heightDime.dimeRelaVal != nil && sbv.heightDime.dimeRelaVal.view == sbv && sbv.heightDime.dimeRelaVal.dime == MyMarginGravity_Horz_Fill)
    {
        pRect->size.height = pRect->size.width * sbv.heightDime.mutilVal + sbv.heightDime.addVal;
        
        if (sbv.isFlexedHeight)
        {
            pRect->size.height = [self heightFromFlexedHeightView:sbv inWidth:pRect->size.width];
        }
        
        pRect->size.height = [self validMeasure:sbv.heightDime sbv:sbv calcSize:pRect->size.height sbvSize:pRect->size selfLayoutSize:selfSize];
        
    }

    
 
    
}

-(CGRect)calcLayoutRect:(CGSize)size isEstimate:(BOOL)isEstimate pHasSubLayout:(BOOL*)pHasSubLayout sizeClass:(MySizeClass)sizeClass
{
    
    CGRect selfRect = [super calcLayoutRect:size isEstimate:isEstimate pHasSubLayout:pHasSubLayout sizeClass:sizeClass];
    CGSize selfSize = selfRect.size;
    NSArray *sbs = self.subviews;
    CGFloat maxWidth = self.leftPadding;
    CGFloat maxHeight = self.topPadding;
    for (UIView *sbv in sbs)
    {
        
        if ((sbv.isHidden && self.hideSubviewReLayout) || sbv.useFrame || sbv.absPos.sizeClass.isHidden)
            continue;
        
        if (!isEstimate)
        {
            sbv.absPos.frame = sbv.frame;
            [self calcSizeOfWrapContentSubview:sbv];
        }

        if ([sbv isKindOfClass:[MyBaseLayout class]])
        {
            if (pHasSubLayout != nil)
                *pHasSubLayout = YES;
            
            MyBaseLayout *sbvl = (MyBaseLayout*)sbv;
            
            if (sbvl.wrapContentHeight && ((sbvl.marginGravity & MyMarginGravity_Horz_Mask) == MyMarginGravity_Vert_Fill || sbvl.heightDime.dimeVal != nil || (sbvl.topPos.posVal != nil && sbvl.bottomPos.posVal != nil)))
            {
                [sbvl setWrapContentHeightNoLayout:NO];
            }
            
            if (sbvl.wrapContentWidth && ((sbvl.marginGravity & MyMarginGravity_Vert_Mask) == MyMarginGravity_Horz_Fill || sbvl.widthDime.dimeVal != nil || (sbvl.leftPos.posVal != nil && sbvl.rightPos.posVal != nil)))
            {
                [sbvl setWrapContentWidthNoLayout:NO];
            }
            
            if (isEstimate)
            {
               [sbvl estimateLayoutRect:sbvl.absPos.frame.size inSizeClass:sizeClass];
                sbvl.absPos.sizeClass = [sbvl myBestSizeClass:sizeClass]; //因为estimateLayoutRect执行后会还原，所以这里要重新设置
            }
        }
        
    
        //计算自己的位置和高宽
        CGRect rect = sbv.absPos.frame;
        [self calcSubView:sbv pRect:&rect inSize:selfSize];
        sbv.absPos.frame = rect;
        
        if ((sbv.marginGravity & MyMarginGravity_Vert_Mask) != MyMarginGravity_Horz_Fill && sbv.widthDime.dimeRelaVal != self.widthDime)
        {
            if (maxWidth < CGRectGetMaxX(rect))
                maxWidth = CGRectGetMaxX(rect);
        }
        
        if ((sbv.marginGravity & MyMarginGravity_Horz_Mask) != MyMarginGravity_Vert_Fill && sbv.heightDime.dimeRelaVal != self.heightDime)
        {
            if (maxHeight < CGRectGetMaxY(rect))
                maxHeight = CGRectGetMaxY(rect);
        }

    }
    
    if (self.wrapContentWidth)
    {
        selfRect.size.width = maxWidth + self.rightPadding;
    }
    
    if (self.wrapContentHeight)
    {
        selfRect.size.height = maxHeight + self.bottomPadding;
    }
    
    selfRect.size.height = [self validMeasure:self.heightDime sbv:self calcSize:selfRect.size.height sbvSize:selfRect.size selfLayoutSize:self.superview.frame.size];
    
    selfRect.size.width = [self validMeasure:self.widthDime sbv:self calcSize:selfRect.size.width sbvSize:selfRect.size selfLayoutSize:self.superview.frame.size];
    
    //调整尺寸和父布局相等的视图的尺寸。
    for (UIView *sbv in sbs)
    {
        if ((sbv.isHidden && self.hideSubviewReLayout) || sbv.useFrame || sbv.absPos.sizeClass.isHidden)
            continue;
        
        if ((sbv.marginGravity & MyMarginGravity_Horz_Mask) == MyMarginGravity_Vert_Fill || (sbv.marginGravity & MyMarginGravity_Vert_Mask) == MyMarginGravity_Horz_Fill)
        {
            CGRect rect = sbv.absPos.frame;
            [self calcSubView:sbv pRect:&rect inSize:selfRect.size];
            sbv.absPos.frame = rect;
        }
        
    }
    
    return selfRect;

}

@end
