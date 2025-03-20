import UIKit

extension UIView {
  func anchor(top: NSLayoutYAxisAnchor? = nil,
              paddingTop: CGFloat = 0,
              left: NSLayoutXAxisAnchor? = nil,
              paddingLeft: CGFloat = 0,
              bottom: NSLayoutYAxisAnchor? = nil,
              paddingBottom: CGFloat = 0,
              right: NSLayoutXAxisAnchor? = nil,
              paddingRight: CGFloat = 0,
              width: CGFloat? = nil,
              height: CGFloat? = nil) {

    translatesAutoresizingMaskIntoConstraints = false

    if let top = top {
      topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
    }

    if let left = left {
      leadingAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
    }

    if let bottom = bottom {
      bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
    }

    if let right = right {
      trailingAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true
    }

    if let width = width {
      widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    if let height = height {
      heightAnchor.constraint(equalToConstant: height).isActive = true
    }
  }

  func center(inView view: UIView, yConstant: CGFloat? = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: yConstant!).isActive = true
  }

  func centerX(inView view: UIView, topAnchor: NSLayoutYAxisAnchor? = nil, paddingTop: CGFloat? = 0) {
    translatesAutoresizingMaskIntoConstraints = false
    centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

    if let topAnchor = topAnchor {
      self.topAnchor.constraint(equalTo: topAnchor, constant: paddingTop!).isActive = true
    }
  }

  func centerY(inView view: UIView, leftAnchor: NSLayoutXAxisAnchor? = nil, paddingLeft: CGFloat? = nil, constant: CGFloat? = 0) {
    translatesAutoresizingMaskIntoConstraints = false

    centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant!).isActive = true

    if let leftAnchor = leftAnchor, let padding = paddingLeft {
      self.leftAnchor.constraint(equalTo: leftAnchor, constant: padding).isActive = true
    }
  }

  func setDimensions(width: CGFloat, height: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: width).isActive = true
    heightAnchor.constraint(equalToConstant: height).isActive = true
  }

  func anchorAsSquare(width: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalToConstant: width).isActive = true
    heightAnchor.constraint(equalToConstant: width).isActive = true
  }

  func setHorizontalDimension(equalTo constraint: NSLayoutDimension, multiplier: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    widthAnchor.constraint(equalTo: constraint, multiplier: multiplier).isActive = true
  }

  func setVerticalDimension(equalTo constraint: NSLayoutDimension, multiplier: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    heightAnchor.constraint(equalTo: constraint, multiplier: multiplier).isActive = true
  }

  func aspectRatio(width: NSLayoutDimension, height: NSLayoutDimension, aspectRatio: CGFloat) {
    translatesAutoresizingMaskIntoConstraints = false
    setHorizontalDimension(equalTo: width, multiplier: 1)
    setVerticalDimension(equalTo: height, multiplier: aspectRatio)
  }

  func addConstraintsToFillView(_ view: UIView) {
    translatesAutoresizingMaskIntoConstraints = false
    anchor(top: view.topAnchor, left: view.leftAnchor,
           bottom: view.bottomAnchor, right: view.rightAnchor)
  }
}

extension UIView {
  func addActivityIndicator(activityView: UIActivityIndicatorView) {
    addSubview(activityView)

    activityView.startAnimating()
    activityView.center(inView: self)
  }
}
