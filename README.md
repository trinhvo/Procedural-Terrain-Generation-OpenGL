# Milestone 1 - Procedural terrain generation

## Contents:

1. Project basis: Perlin noise, heightmap and coloring
2. Perlin noise generation and variations
3. Normal map from noise texture
4. First person view camera
5. Tesselation shader
6. Work distribution

## 1. Project basis: Perlin noise, heightmap and coloring

Initial Perlin noise implementation following GPUGems

Perlin noise was first implemented using the permutation table to generate pseudo-random gradients. The following the algorithm, we obtaint our perlin noise. Our has the signature perlin_nosie(float x, float y). Multiplying the x and y parameters, initially given   as uv.x and uv.y allows us to modify the frequency.

Initial OctavePerlin implementation that adds several octaves of Perlin noise

The implementation of the Brownian motion was mainly generating and stacking multiple perlin noises at different frequencies.

### 1.2. Height and angle based colouring of terrain

Mapping normal vector to color

Passing the vpoint vector from the vshader allows us to calculate the slope by scalar product with the vertical vector )(0, 0, 1) and vpoint normalized). Now we have an alpha angle with range [-1, 1]. Now we can choose an arbitrary threshold. Knowing that angle 0     means our normal vector is horizontal, we have highest slope. Instead of only color with some grey when the slope is higher than the threshold, we found more realistic to mix the rock color with the already set color for the given height, the mix ratio being a function of the slope allowed us to define a smooth transition between, say, grass and rock, up to some other threshold where we directly color with rock (this seemed to imitate a natural coloring pretty well. One can think of a cliff this way: When the slope is low there is grass (less as the slope increase), but at some point, there's no grass anymore.


## 2. Perlin noise improvements and variations
Since the perlin noise is at the heart of our procedural project, we took some time experiment with and better understand its complicated behaviors.

Moving on from the initial Perlin noise implementation, we tweaked the permutation array generation to make it faster (with pre-caching) and random (using c++11's random). From there, we implemented several fBm:

- Ridged noise: a ridged noise and fBm
- Multifractal: this is Kenton Musgrave's mutifractal algorithm
- pow fBm: this is an octave based fBm were the power of the Perlin noise is taken

We then proceeded to implement an utility that would display the different noise side by side so as to be able to compare them.
On the screenshots below: 

- OctavePerlin is on the top left corner,
- Pow-fBm is on the bottom left corner, 
- Ridged-noise is on the top right corner,
- and Multifractal (fed with an initial ridged-noise) is on the bottom right corner.

<img src="http://img4.hostingpics.net/pics/896863photo20170411103519.jpg" alt="Perlin noise variations" />

<img src="http://img4.hostingpics.net/pics/834107photo20170411103516.jpg"  alt="Perlin noise variations" />

Our work on the noise generation is not finished, yet. We are still looking for an implementation or combination of noise that will provide the most realistic results. It's incredible how time consuming it is to tweak the different parameters so as to produce the best heightmap. Our plans for improvement are the following:

- Further optimize fBm generation's speed by extracting the Perlin noise in a different texture.
- Find the most appropriate random distribution for the permutation array generation.
- Settle for a noise implementation. Our favorite at the moment is a mix of Perlin noise and ridged-noise in a multifractal like fBm. Due to technical problems (Julien's computer died...) we couldn't implement it in the project, yet.
- Maybe implement erosion.

## 3. Normal map from noise texture
One of the main disadvantage with flat shading is that it requires to compute the normal for each fragment.
Such computations can be very inefficient because when multiple fragments share the same primitive, they will
have the same normal and we will compute multiple times the same value.

Therefore, we choose to compute once and for all the terrain normals and store them in a texture that will
then be sampled by the fragment shader.

We built a new class which takes as input a Perlin noise texture and output the corresponding normal map, 
stored in a texture.

The additional advantage that this technique offers is that when used with the tesselation shader, the shading 
can still leverage the normal map to simulate a high level of detail, even if the underlying mesh is at low
resolution.

<img src="https://lkieliger.ch/docs/pictures/cgx/normalMapCompil.png">

## 4. First person view camera
We followed the tutorial on learnopengl.com to implement the first person view camera. At the end of the 
tutorial the author of the website offers a class which encapsulates the behavior of the camera. As we
understood the effect of the code, we took the class from learnopengl.com and slightly adapted it for our
needs. Therefore, most of the code in this class is *NOT* our work.

## 5. Tesselation shader
The helper class was modified in order to be abe to compile two new types of shaders: the Tesselation 
Control Shader and the Tesselation Evaluation Shader.

The grid class was modified to render GL_PATCHES instead of GL_ELEMENTS, the vertices are now indexed
in squares instead of triangles and in counter clockwise order. That is, bottom left is vertex 0, 
bottom right 1, top right 2, top left 3.

### 5.1 Tesselation Control Shader
The control shader receives patches of 4 vertices and specifies the outer and inner levels of tesselation.

The inner tesselation levels are simply the average of the corresponding outer levels. That is, the horizontal 
inner tesselation level is the average of the outer levels on the left and right edges and the vertical inner
tesselation level is the average of the outer levels on the top and bottom edges.

The outer tesselation levels are computed based on the distance between the vertices of the edge and the camera.
We take the mean camera distance of each pair of vertices per quad edge and use it to interpolate the 
appropriate tesselation level.
To this end we specified a maximum/minimum tesselation level and a maximum/minimum distance at which the tesselation
becomes active.

Finally, we cull the patches that are outside the camera view frustrum to save computation time.
 
### 5.2 Tesselation Evaluation Shader
The evaluation shader receives all generated primitives. It first compute the primitive attributes such as
the 3D position or 2D texture coordinates by interpolating the values of the control points (the vertices)
forming the patch based on the gl_TessCoord value, which indicates the position of the generated primitive
inside the patch.

We then sample the heightmap to define the height of each vertex and the normal map to get the normal at the
vertex position.

Finally we perform model, view and projection transforms on each vertex and apply some diffuse lighting on it.

You can see the results on the screenshots below three different stages of tesselation based on vertex distance to the camera.

<img src="https://lkieliger.ch/docs/pictures/cgx/tessCompil.png">

### 5.3 Further improvements
At the moment, we use a fixed patch size for the tesselation. That is, the gris is always represented with a fixed number of vertices. While this allow for a simple implementation of the tesselation shader, when patches are really far away they may end up in the same fragment after rasterization. Therefore we would like to lower the level of details even more.

This can be done by represening the terrain with a quadtree, where each leaf of the tree defines a region of the grid. This way, we can recursively split the quadtree into 4 child nodes, which would then represent 4 sub-patches on the grid, based on the distance to the camera.

## Work distribution

**Isaac Leimgruber**
- implemented section `1. Project basis: Perlin noise, fBm, heightmap and coloring`

**Julien Harbulot**
- implemented section `2. Perlin noise generation and variations`
- researched the best way to make the terrain infinite, but couldn't implement a working version for this assignment due to technical problems (computer died).

**Leandro Kieliger**
- implemented sections `3. Normal map from noise texture` and `5. Tesselation shader`.