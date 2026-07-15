export class ProductListRenderer {
  constructor(containerSelector) {
    this.container = document.querySelector(containerSelector);
  }

  renderProducts(productCatalog) {
    if (!this.container) {
      return;
    }

    this.container.innerHTML = '';
    productCatalog.forEach((soapProduct) => {
      this.container.append(this.createProductListItem(soapProduct));
    });
  }

  renderError(message) {
    if (!this.container) {
      return;
    }

    this.container.innerHTML = '';

    const errorItem = document.createElement('li');
    const errorParagraph = document.createElement('p');
    errorParagraph.textContent = message;
    errorItem.append(errorParagraph);

    this.container.append(errorItem);
  }

  createProductListItem(soapProduct) {
    const listItem = document.createElement('li');
    listItem.classList.add('product-item');
    const productArticle = document.createElement('article');
    productArticle.classList.add('product-card');

    const nameHeading = document.createElement('h3');
    nameHeading.textContent = soapProduct.name;
    nameHeading.classList.add('product-name');

    const productImage = document.createElement('img');
    productImage.src = soapProduct.imageSrc;
    productImage.alt = soapProduct.imageAlt;
    productImage.width = 400;
    productImage.height = 300;
    productImage.loading = 'lazy';
    productImage.classList.add('product-image');

    const descriptionParagraph = document.createElement('p');
    descriptionParagraph.textContent = soapProduct.description;
    descriptionParagraph.classList.add('product-description');

    const priceParagraph = document.createElement('p');
    const priceData = document.createElement('data');
    priceData.value = soapProduct.priceValue;
    priceData.textContent = soapProduct.priceDisplay;
    priceParagraph.append(priceData);
    priceParagraph.classList.add('price');

    const availabilityParagraph = document.createElement('p');
    const availabilityLabel = document.createElement('strong');
    availabilityLabel.textContent = 'Availability:';
    availabilityParagraph.append(availabilityLabel, ` ${soapProduct.availability}`);
    availabilityParagraph.classList.add('availability');

    const moreInfoParagraph = document.createElement('p');
    const moreInfoLink = document.createElement('a');
    moreInfoLink.href = soapProduct.moreInfoUrl;
    moreInfoLink.textContent = 'More Info';
    moreInfoLink.classList.add('more-info');
    moreInfoParagraph.append(moreInfoLink);

    productArticle.append(
      nameHeading,
      productImage,
      descriptionParagraph,
      priceParagraph,
      availabilityParagraph,
      moreInfoParagraph
    );

    listItem.append(productArticle);
    return listItem;
  }
}
