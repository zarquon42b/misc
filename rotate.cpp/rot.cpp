#include <iostream>
#include <Eigen/Dense>
#include <vector>
#include <fstream>
using namespace std;
using namespace Eigen;

Matrix4f mirmat(bool mir) {
  Matrix4f mirmat = Matrix4f::Zero();
  mirmat.diagonal().fill(1);
  if (mir)
    mirmat(1,1) = -1;
  return mirmat;
}

std::vector<float> readCSV(string filename) {
  ifstream infile;
  vector<float>array;
  int i=0;
  char cNum[50] ;
  infile.open (filename.c_str(), ifstream::in);
  if (infile.is_open()) {
    while (infile.good()) {
      infile.getline(cNum, 30, ',');
      array.push_back(atof(cNum)) ;
      i++ ;
    }
    infile.close();
  } else {
    cout << "Error opening file" <<endl;
  }
  return array;
}

double ctrace(const MatrixXf& X) {
  MatrixXf XtX = X.transpose()*X;
  double out = XtX.diagonal().sum();
  return out;
}

MatrixXf crossprod(const MatrixXf& X, const MatrixXf& Y) {
  MatrixXf out = X.transpose()*Y;
  return out;
}
Matrix4f rotationmat(const Matrix3f& gam, const Vector3f& trans, const Vector3f& transy, float beta, bool forceReflect) {
  Matrix4f hgamm, htrans, htransy, scalemat;
  hgamm = htrans = htransy = scalemat = Matrix4f::Zero();
  hgamm(3,3) = 1;
  hgamm.topLeftCorner(3,3) = gam;
  htrans.diagonal().fill(1);
  htrans.topRightCorner(3,1) = trans; 
  htransy.diagonal().fill(1);
  htransy.topRightCorner(3,1) = -transy; 
  scalemat.diagonal().fill(1);
  Matrix3f b;b.fill(0.0); b.diagonal().fill(beta);
  scalemat.topLeftCorner(3,3) = b;
  Matrix4f mir4 = mirmat(forceReflect);
  Matrix4f out = htrans*scalemat*hgamm.transpose()*mir4*htransy;
  return out;
}
  
MatrixXf mat2hom(const MatrixXf& in){
  MatrixXf hom(in.cols()+1,in.rows());
  hom.fill(1);
  hom.topLeftCorner(3,hom.cols()) = in.transpose();
  return hom;
}
MatrixXf hom2mat(const MatrixXf& in){
  MatrixXf unhom(in.cols(),in.rows()-1);
  unhom = in.topLeftCorner(3,in.cols());
  return unhom.transpose();
}
MatrixXf scale(MatrixXf X) {
  VectorXf mean = X.colwise().mean();
  for (int i=0; i < X.rows();i++) {
    X.row(i) -=  mean;
  }
  return X;
}

void refcheck(MatrixXf& u, MatrixXf& v) {
  float chk1 = u.eigenvalues().real().prod();
  float chk2 = v.eigenvalues().real().prod();
  if ((chk1 < 0) && (chk2 > 0)) {
    v.col(v.cols()-1) *=-1;
  }
  if ((chk2 < 0) && (chk1 > 0)) {
    u.col(u.cols()-1) *=-1;
  }
}

void help() {
  cout << "  USAGE: " << endl;
  cout << "  rotate [--scale | -- reflect | --forceReflect] -X fixedLandmarks.txt -Y movingLandmarks.txt" << endl;
  cout << endl;
  cout << "        --scale            allow scaling" << endl;
  cout << "        --reflect          allow reflection" << endl;
  cout << "        --forceReflect     force reflection" << endl;
  cout << "        -X                 Fix landmarks: pass text file with all coordinates in one row, separated by comma and like x1,x2,x3,..,y1,y2,y3,..,z1,z2,z3,..." << endl;
  cout << "        -Y                 Moving landmarks: pass text file with all coordinates in one row, separated by comma and like x1,x2,x3,..,y1,y2,y3,..,z1,z2,z3,..." << endl;
}
int main(int argc, char **argv) {
  bool scaling = false;
  bool reflect = false;
  bool forceReflect = false;
  char xfile[256] = "n";
  char yfile[256] = "n";
  for (int i = 1; i < argc; i++) {
    if (strcmp("--scale", argv[i]) == 0)
      scaling = true;
    if (strcmp("--forceReflect", argv[i]) == 0)
      forceReflect = true;
    if (strcmp("--reflect", argv[i]) == 0)
      reflect = true;
    if (strcmp("-X", argv[i]) == 0) {
      strcpy(xfile,argv[i+1]);
    }
    if (strcmp("-Y", argv[i]) == 0) {
      strcpy(yfile,argv[i+1]);
    }
    if (strcmp("--help", argv[i]) == 0 || strcmp("?", argv[i]) == 0) {
      help();
      return 1;
    }
  }
 
  MatrixXf X;
  MatrixXf Y;
  
  if (strcmp("n",xfile) == 0 || strcmp("n",yfile) == 0) {
    cout << "DEMO:" << endl;
    X.resize(10,3);
    X << 124.899, 44.6372, 76.5035, 124.837, 44.896, 80.0746, 128.598, 48.4627, 77.9002, 121.321, 48.3923, 77.8763, 129.007, 56.1819, 28.4977, 117.574, 56.16, 29.201, 132.355, 57.219, 30.4904, 113.275, 57.2417, 32.0883, 123.207, 54.4333, 22.495, 124.49, 40.7635, 44.6354;
    Y.resize(10,3);
    Y << 115.112, 34.1478, 81.6128, 114.605, 38.2015, 85.0266, 118.315, 40.2561, 81.8498, 110.955, 40.2995, 82.2631, 118.949, 40.4251, 33.5079, 108.095, 39.9903, 32.5014, 121.982, 43.0974, 36.8266, 105.241, 41.9247, 36.2053, 113.7, 37.9291, 29.7025, 113.59, 29.7977, 53.7322;
 
  } else {
    vector<float>x0 = readCSV(string(xfile));
    vector<float>y0 = readCSV(string(yfile));
    
    X = MatrixXf::Map(x0.data(),x0.size()/3,3);
    Y = MatrixXf::Map(y0.data(),y0.size()/3,3);
    if (x0.size() != y0.size()) {
      cout << "ERROR: X and Y differ in dimensionality" << endl;
      return 1;
    }
  }
  MatrixXf X1 = scale(X);
  MatrixXf Y1 = scale(Y); 
  if (forceReflect) {
    Matrix4f mir = mirmat(true);
    Y1 = Y1*mir.topLeftCorner(3,3);
  }
  float beta = 1;
  Vector3f trans = X.row(0)-X1.row(0);
  Vector3f transy = Y.row(0)-Y1.row(0);
  MatrixXf XY = crossprod(X1,Y1);
  JacobiSVD<MatrixXf> svd(XY, ComputeFullU | ComputeFullV);
  MatrixXf u = svd.matrixU();
  MatrixXf v = svd.matrixV();
  if (!reflect)
    refcheck(u,v);
  if (scaling) {
    beta = svd.singularValues().sum()/ctrace(Y1);
  }
  Matrix3f gamm = v*u.transpose();
  Matrix4f trafo = rotationmat(gamm,trans,transy,beta,forceReflect);
  MatrixXf Yrot = hom2mat(trafo*mat2hom(Y));
  cout << "here comes the transformation:" << endl << trafo << endl << endl;
  cout << "here come the transformed coordinates:" << endl <<Yrot << endl << endl;
  cout << "scaling = " << scaling << endl;
  cout << "reflection allowed = " << reflect << endl;
  return 0;
}
  

