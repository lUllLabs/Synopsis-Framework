//
//  MedianCutOpenCV.cpp
//  Synopsis
//
//  Created by vade on 7/15/16.
//  Copyright © 2016 metavisual. All rights reserved.
//

#include "MedianCutOpenCV.hpp"

#include <queue>
#include <algorithm>

#include "CIEDE2000.h"


namespace MedianCutOpenCV
{
    ColorCube::ColorCube(cv::Mat mat, bool useDeltaE)
    {
        // todo:: assert depth = 3 or whatever...
        // todo:: assert colorspace is LAB if we use CIEDE2000?

        // unroll the image and then make a vector of colors from it
        numColors = mat.rows * mat.cols;
        
        // We reshape so we can use a 'linear' ROI
        image = mat.reshape(3, numColors);
        useCIEDE2000 = useDeltaE;
        
        float min = std::numeric_limits<float>::min();
        float max = std::numeric_limits<float>::max();
        minColor = cv::Vec3f(min, min, min);
        maxColor = cv::Vec3f(max, max, max);
        
        shrink();
    }
    
    // This is Euclidean based on color
    void ColorCube::shrink()
    {
        if(useCIEDE2000)
        {
//            double lastMinDelta = DBL_MAX;
//            double lastMaxDelta = DBL_MIN;
//            for(int i = 1; i < numColors; i++ )
//            {
//                double mindelta = CIEDE2000::CIEDE2000(minColor, colors[i]);
//                double maxdelta = CIEDE2000::CIEDE2000(maxColor, colors[i]);
//                
//                if( mindelta < lastMinDelta)
//                {
//                    minColor = colors[i];
//                    lastMinDelta = mindelta;
//                }
//                
//                if( maxdelta > lastMaxDelta)
//                {
//                    maxColor = colors[i];
//                    lastMaxDelta = maxdelta;
//                }
//            }
        }
        else
        {
            std::vector<cv::Mat>channels;
            cv::split(image, channels);
            
            double minR, maxR, minG, maxG, minB, maxB = 0.0;
            cv::minMaxLoc(channels[0], &minR, &maxR, NULL, NULL, cv::noArray());
            cv::minMaxLoc(channels[1], &minG, &maxG, NULL, NULL, cv::noArray());
            cv::minMaxLoc(channels[2], &minB, &maxB, NULL, NULL, cv::noArray());
            
            minColor = cv::Vec3f(minR, minG, minB);
            maxColor = cv::Vec3f(maxR, maxG, maxB);            
        }
    }
    
    // Call Shrink prior to this having
    int ColorCube::longestSideIndex() const
    {
        int m = maxColor[0] - minColor[0];
        int maxIndex = 0;
        for(int i = 1; i < 3; i++)
        {
            int diff = maxColor[i] - minColor[i];
            if (diff > m)
            {
                m = diff;
                maxIndex = i;
            }
        }

        return maxIndex;
    }
    
    float ColorCube::longestSideLength() const
    {
        int i = longestSideIndex();
        return maxColor[i] - minColor[i];
    }
    
    int ColorCube::volume() const
    {
        cv::Vec3f diff;
        for ( int i = 0; i < 3; i++ )
        {
            diff[i] = maxColor[i] - minColor[i];
        }
        
        int volume = diff[0];
        
        for ( int i = 1; i < 3; i++ )
        {
            volume *= diff[i];
        }
        
        return volume;
    }

    bool ColorCube::operator < (const ColorCube& other) const
    {
        // Euclidiean?
        if(useCIEDE2000)
        {
            float delta =  CIEDE2000::CIEDE2000(maxColor, other.maxColor) ;
            
            return ( delta >= 0 );
        }
        else
            return ( longestSideLength() < other.longestSideLength() );
    }
        
    std::list< std::pair<cv::Vec3f,unsigned int> > medianCut(cv::Mat image, unsigned int desiredSize, bool useCIEDE2000)
    {        
        ColorCube initialColorCube(image, useCIEDE2000);
        
        return medianCut(initialColorCube, desiredSize, useCIEDE2000);
    }

    std::list< std::pair<cv::Vec3f,unsigned int> > medianCut(ColorCube initialColorCube, unsigned int desiredSize, bool useCIEDE2000)
    {
        std::priority_queue<ColorCube> colorCubeQueue;
        
        colorCubeQueue.push(initialColorCube);
        
        while (colorCubeQueue.size() < desiredSize && colorCubeQueue.top().numColors > 1)
        {
            // Pop our first color cube off the stack
            ColorCube currentColor = colorCubeQueue.top();

            colorCubeQueue.pop();

            // number of colors we have and channel we use for sorting
            int numColors = currentColor.numColors;
            int longestSide = currentColor.longestSideIndex();
            
            // Initial sorting and Region of Interest locations
            int half = MAX((numColors + 1) / 2, 1);
            int firstIndex = 0;
            
            // Pull out channel and partially sort it
            std::vector<cv::Mat>channels;
            cv::split(currentColor.image,channels);

            cv::Mat channel = channels[longestSide];
            
            std::nth_element( channel.begin<float>(), channel.begin<float>() + half, channel.end<float>());

            // put back our sorted channel
            channels[longestSide] = channel;
            cv::merge(channels, currentColor.image);

            // subdivide via ROI
            cv::Rect firstROI = cv::Rect(0, firstIndex,1, half);
            cv::Rect lastROI = cv::Rect(0, half, 1, MAX(half - 1, 1));

            ColorCube lowerColors(currentColor.image(firstROI), useCIEDE2000);
            ColorCube higherColors(currentColor.image(lastROI), useCIEDE2000);

            colorCubeQueue.push(lowerColors);
            colorCubeQueue.push(higherColors);
        }

        std::list<std::pair<cv::Vec3f, unsigned int> > result;
        while(!colorCubeQueue.empty())
        {
            ColorCube currentColorCube = colorCubeQueue.top();
            colorCubeQueue.pop();
            
            cv::Scalar averagePoint = cv::mean(currentColorCube.image);

            if(useCIEDE2000)
            {
//                // find closest color in the color cube to our average;
//                double delta = DBL_MAX;
//                cv::Vec3f closestColor;
//                for(int i = 0; i < currentColorCube.numColors; i++)
//                {
//                    double currentDelta = CIEDE2000::CIEDE2000(averagePoint, currentColorCube.colors[i]);
//                    if(currentDelta < delta)
//                    {
//                        delta = currentDelta;
//                        closestColor = currentColorCube.colors[i];
//                    }
//                }
//                
//                result.push_back( std::make_pair( closestColor, currentColorCube.numColors ) );
            }
            else
            {
                result.push_back( std::make_pair( cv::Vec3f(averagePoint[0], averagePoint[1], averagePoint[2]), currentColorCube.numColors ) );
            }
        }
        
        return result;

    }
    
   
    

}
