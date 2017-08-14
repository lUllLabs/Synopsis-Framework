//
//  MedianCutOpenCV.hpp
//  Synopsis
//
//  Created by vade on 7/15/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#ifndef MedianCutOpenCV_hpp
#define MedianCutOpenCV_hpp

#include <stdio.h>
#include <list>
#import <opencv2/opencv.hpp>

namespace MedianCutOpenCV
{
    class ColorCube
    {
        
    public:
        ColorCube(cv::Mat image, bool useCIEDE2000);

        cv::Mat image;
        int numColors;
        
        cv::Vec3f minColor;
        cv::Vec3f maxColor;
        
        int longestSideIndex() const;
        float longestSideLength() const;
        int volume() const;
        
        bool operator < (const ColorCube& other) const;
//        bool operator < (ColorCube& other);
      
    private:
        bool useCIEDE2000;
        
        // Reclaculate our min and max colors
        void shrink();
    };

    
    template <int index>
    class CoordinateColorComparator
    {
    public:
        bool operator()(const cv::Vec3f left, const cv::Vec3f right)
        {
            return left[index] < right[index];
        }
    };
    
    /// calculate a median cut of the input image and return pairs of (median colour,point count)
    std::list< std::pair<cv::Vec3f,unsigned int> > medianCut(cv::Mat image, unsigned int desiredSize, bool useCIEDE2000);
    std::list< std::pair<cv::Vec3f,unsigned int> > medianCut(ColorCube initialColorCube, unsigned int desiredSize, bool useCIEDE2000);

} // End Name Space

#endif /* MedianCutOpenCV_hpp */
