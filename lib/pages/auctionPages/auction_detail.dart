import 'package:collectionapp/viewModels/auction_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collectionapp/models/AuctionModel.dart';
import 'package:collectionapp/design_elements.dart';
import 'package:collectionapp/countdown_timer.dart';
import 'package:photo_view/photo_view.dart';

class AuctionDetail extends StatelessWidget {
  final AuctionModel auction;

  const AuctionDetail({super.key, required this.auction});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuctionDetailViewModel(auction),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: ProjectAppbar(
          titleText: "Auction Details",
          actions: [
            Consumer<AuctionDetailViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.currentUser.uid == auction.creatorId) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "Edit") {
                        _showEditDialog(context, viewModel);
                      } else if (value == "Delete") {
                        _showDeleteConfirmation(context, viewModel);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: "Edit",
                        child: Text("Edit"),
                      ),
                      const PopupMenuItem<String>(
                        value: "Delete",
                        child: Text("Delete"),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
        body: Consumer<AuctionDetailViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Carousel
                    _buildImageCarousel(auction.imageUrls, context),
                    const SizedBox(height: 16),
                    // Auction Details
                    _buildAuctionDetails(viewModel),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        CountdownTimer(
                          endTime: auction.endTime,
                          auctionId: auction.id,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: Consumer<AuctionDetailViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.currentUser.uid != auction.creatorId) {
              return GestureDetector(
                onTap: () => _showBidDialog(context, viewModel),
                child: const FinalFloatingDecoration(
                  buttonText: "Place a Bid",
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imageUrls, BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 6,
          ),
        ],
      ),
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showPhotoDialog(context, imageUrls[index]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuctionDetails(AuctionDetailViewModel viewModel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auction.description,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                text: "Price: ",
                style: ProjectTextStyles.cardHeaderTextStyle,
                children: [
                  TextSpan(
                    text: "\$${auction.startingPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.bidderInfo != null
                  ? "Last Bidder: ${viewModel.bidderInfo!.firstName}"
                  : "No bids yet",
              style: ProjectTextStyles.cardDescriptionTextStyle,
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.creatorInfo != null
                  ? "Created by: ${viewModel.creatorInfo!.firstName}"
                  : "",
              style: ProjectTextStyles.cardHeaderTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPhotoDialog(BuildContext context, String imageUrl) {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBidDialog(
      BuildContext context, AuctionDetailViewModel viewModel) async {
    double? newBid;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text(
            "Place Your Bid",
            style: ProjectTextStyles.appBarTextStyle,
          ),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Minimum Bid: \$${auction.startingPrice + 1}",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              newBid = double.tryParse(value);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: ProjectTextStyles.appBarTextStyle.copyWith(
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (newBid != null) {
                  viewModel.placeBid(newBid!, context);
                  Navigator.of(context).pop();
                }
              },
              style: ProjectDecorations.elevatedButtonStyle,
              child: const Text(
                "Submit Bid",
                style: ProjectTextStyles.buttonTextStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<void> _showEditDialog(
    BuildContext context, AuctionDetailViewModel viewModel) async {
  final TextEditingController nameController =
      TextEditingController(text: viewModel.auction.name);
  final TextEditingController descriptionController =
      TextEditingController(text: viewModel.auction.description);

  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text("Edit Auction"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Auction Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 3,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.editAuction(
                context,
                nameController.text,
                descriptionController.text,
              );
              Navigator.of(context).pop();
            },
            child: const Text("Save"),
          ),
        ],
      );
    },
  );
}

Future<void> _showDeleteConfirmation(
    BuildContext context, AuctionDetailViewModel viewModel) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Delete Auction"),
        content: const Text("Are you sure you want to delete this auction?"),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1) ViewModel'den silme işlemini çalıştır
              bool success = await viewModel.deleteAuction();

              // 2) Dialog'u kapat
              Navigator.of(context).pop();

              // 3) İşlem başarılıysa snackBar göster ve AuctionDetail sayfasını pop et
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Auction deleted successfully!")),
                );
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error deleting auction.")),
                );
              }
            },
            child: const Text("Delete"),
          ),
        ],
      );
    },
  );
}
